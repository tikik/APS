# APS analytics output verification (aggregated CSV files only)
# Run from project root after 04, 05, 06, and 08 have produced their CSVs.
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(yaml))

cfg <- yaml::read_yaml("config.yml")
out <- cfg$paths$output
small_n <- cfg$privacy$small_cell_review_threshold
if (is.null(small_n)) small_n <- 20
failures <- character()
warnings <- character()

check <- function(ok, label) {
  if (isTRUE(ok)) message("PASS: ", label)
  else {message("FAIL: ", label); failures <<- c(failures, label)}
}
flag <- function(condition, message_text) {
  if (isTRUE(condition)) {message("REVIEW: ", message_text); warnings <<- c(warnings, message_text)}
}
load_output <- function(filename) {
  p <- file.path(out, filename)
  if (!file.exists(p)) {failures <<- c(failures, paste("Missing", filename)); return(NULL)}
  readr::read_csv(p, show_col_types = FALSE)
}
check_pct <- function(df, column, name) {
  if (is.null(df) || !column %in% names(df)) return(invisible(NULL))
  v <- suppressWarnings(as.numeric(df[[column]]))
  check(all(is.na(v) | (is.finite(v) & v >= 0 & v <= 100)), paste(name, column, "within 0-100"))
}

D <- load_output("Grade6_District.csv")
S <- load_output("Grade6_Schools.csv")
F <- load_output("Grade6_Forecast.csv")
SF <- load_output("Grade6_School_Forecast.csv")
SC <- load_output("Grade6_School_Comparison.csv")
P <- load_output("Grade6_School_Population.csv")
C <- load_output("Grade6_School_Complete.csv")
E <- load_output("Grade6_School_Equity_Forecast.csv")
N <- load_output("Grade6_Near_Benchmark.csv")
T <- load_output("Grade6_Trend_With_Forecast.csv")

for (item in list(list(D,"Mid_Above_Pct","District"),list(S,"Mid_Above_Pct","School"),
                  list(F,"Projected_EOY_Pct","Equity forecast"),
                  list(SF,"Projected_EOY_Pct","School forecast"),
                  list(C,"Projected_EOY_Pct","Complete school"),
                  list(E,"Projected_EOY_Pct","School/equity"),
                  list(T,"Mid_Above_Pct","Trend"))) {
  check_pct(item[[1]], item[[2]], item[[3]])
}

if (!is.null(D) && !is.null(S)) {
  d <- D |> mutate(Window = sub(" .*", "", `Norming Window`)) |>
    select(`Academic Year`, Window, Students, Mid_Above_Count, Valid_Placements)
  s <- S |> mutate(Window = sub(" .*", "", `Norming Window`)) |>
    group_by(`Academic Year`, Window) |>
    summarise(across(c(Students, Mid_Above_Count, Valid_Placements), sum, na.rm = TRUE), .groups="drop")
  joined <- inner_join(d, s, by=c("Academic Year", "Window"), suffix=c("_district", "_schools"))
  check(nrow(joined) == nrow(D) && nrow(d) == nrow(D), "Every district year/window has school totals")
  for (col in c("Students", "Mid_Above_Count", "Valid_Placements")) {
    check(all(joined[[paste0(col,"_district")]] == joined[[paste0(col,"_schools")]]),
          paste("District versus school", col, "reconciles"))
  }
}

if (!is.null(F)) {
  check(all(F$Students_With_Probability <= F$Students), "Equity coverage not greater than cohort")
  flag(any(F$Students_With_Probability < F$Students), "Some equity-group students have no forecast")
}
if (!is.null(SC)) {
  check(all(SC$Students_With_Probability <= SC$Students), "School coverage not greater than cohort")
  flag(any(SC$Students_With_Probability < SC$Students), "Some school students have no forecast")
  comparison <- round(SC$Projected_EOY_Pct - SC$Previous_EOY_Pct, 1)
  check(all(is.na(comparison) | is.na(SC$Change_PP) | abs(comparison - SC$Change_PP) <= .11),
        "School percentage-point changes reconcile")
}
if (!is.null(P)) {
  check(all(P$Hispanic + P$Black <= P$Students), "Demographic counts do not exceed assessed population")
  flag(any(P$Students < small_n, na.rm=TRUE), "Small assessed school cohorts need disclosure review")
}
if (!is.null(E)) {
  check(all(E$Students_With_Probability <= E$Students), "School/equity forecast coverage valid")
  check(all(E$Early_On_Students <= E$Students), "Early On counts do not exceed group size")
  flag(any(E$Students < small_n, na.rm=TRUE), "Small school-by-equity cells need disclosure review")
}
if (!is.null(N)) check(all(N$Students_With_Probability <= N$Early_On_Students),
                       "Near-benchmark coverage within eligible group")
if (!is.null(T)) {
  check(sum(T$Status == "Projected", na.rm=TRUE) == 1, "Trend has exactly one projected row")
}

# Additional reconciliation: current Winter school totals to district counts.
if (!is.null(D) && !is.null(P)) {
  current <- D |> filter(`Academic Year` == cfg$analysis$forecast_year, grepl("^Winter", `Norming Window`))
  if (nrow(current) == 1L) {
    check(sum(P$Students) == current$Students[1], "Current Winter school population equals district")
  }
}
if (!is.null(P) && !is.null(C)) {
  check(nrow(P) == nrow(C) && setequal(P$School, C$School), "School population and complete summary cover same schools")
}

cat("\nQuality checks:", length(failures), "failure(s),", length(warnings), "review flag(s).\n")
if (length(failures)) stop("Quality checks failed:\n- ", paste(failures, collapse="\n- "))
message("Checks passed. Review flags are not automatically safe for public release.")

