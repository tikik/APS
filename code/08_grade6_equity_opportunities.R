
library(tidyverse)

output <- if (exists("config")) config$paths$output else "output"
dir.create(output, recursive = TRUE, showWarnings = FALSE)

# Run File 05 to load grade6 and forecast
if (!exists("forecast") || !exists("grade6") || !exists("school_comparison")) {
  source("05_grade6_forecast.R", local = TRUE)
}
stopifnot(exists("forecast"), exists("grade6"), exists("school_comparison"))

# 1. Current Winter population by school
population <- forecast |>
  group_by(School) |>
  summarise(
    Students = n_distinct(`Student ID`),
    Hispanic = n_distinct(
      `Student ID`[Equity_Group == "Hispanic or Latino"]
    ),
    Black = n_distinct(
      `Student ID`[Equity_Group == "Black (Non-Hispanic)"]
    ),
    .groups = "drop"
  ) |>
  mutate(
    Hispanic_Pct = round(100 * Hispanic / Students, 1),
    Black_Pct = round(100 * Black / Students, 1)
  )

write_csv(
  population,
  file.path(output, "Grade6_School_Population.csv")
)

# 2. Complete school summary
current_achievement <- forecast |>
  group_by(School) |>
  summarise(
    Current_Mid_Above_Pct = round(
      100 * mean(Mid_Above, na.rm = TRUE), 1
    ),
    .groups = "drop"
  )

school_summary <- population |>
  left_join(current_achievement, by = "School") |>
  left_join(
    school_comparison |>
      dplyr::select(
        School, Previous_Students, Previous_EOY_Pct,
        Students_With_Probability, Projected_EOY_Pct,
        Change_PP
      ),
    by = "School"
  )

write_csv(
  school_summary,
  file.path(output, "Grade6_School_Complete.csv")
)

# 3. Achievement and forecasts by school and equity group
school_equity <- forecast |>
  group_by(School, Equity_Group) |>
  summarise(
    Students = n_distinct(`Student ID`),
    Current_Mid_Above_Pct = round(
      100 * mean(Mid_Above, na.rm = TRUE), 1
    ),
    Early_On_Students = sum(
      `Overall Relative Placement` == "Early On Grade Level",
      na.rm = TRUE
    ),
    Students_With_Probability = sum(!is.na(Probability)),
    Expected_EOY_Mid_Above = round(
      sum(Probability, na.rm = TRUE), 1
    ),
    Projected_EOY_Pct = round(
      100 * mean(Probability, na.rm = TRUE), 1
    ),
    .groups = "drop"
  )

write_csv(
  school_equity,
  file.path(output, "Grade6_School_Equity_Forecast.csv")
)

# 4. Near-benchmark opportunities: priority groups
near_benchmark <- forecast |>
  filter(
    Equity_Group %in% c(
      "Hispanic or Latino",
      "Black (Non-Hispanic)"
    ),
    `Overall Relative Placement` == "Early On Grade Level"
  )

opportunity <- near_benchmark |>
  group_by(School, Equity_Group) |>
  summarise(
    Early_On_Students = n_distinct(`Student ID`),
    Mean_Winter_Score = round(
      mean(as.numeric(`Overall Scale Score`), na.rm = TRUE), 1
    ),
    Students_With_Probability = sum(!is.na(Probability)),
    Expected_To_Reach_Mid = round(
      sum(Probability, na.rm = TRUE), 1
    ),
    .groups = "drop"
  ) |>
  arrange(desc(Early_On_Students))

write_csv(
  opportunity,
  file.path(output, "Grade6_Near_Benchmark.csv")
)

# 5. Population and equity rankings
cat("\nLargest schools:\n")
population |> arrange(desc(Students)) |> print(n = 10)

cat("\nSmallest schools:\n")
population |> arrange(Students) |> print(n = 10)

cat("\nMost Hispanic/Latino students:\n")
population |> arrange(desc(Hispanic)) |> print(n = 10)

cat("\nMost Black non-Hispanic students:\n")
population |> arrange(desc(Black)) |> print(n = 10)

cat("\nLargest projected improvement:\n")
school_summary |> arrange(desc(Change_PP)) |> print(n = 10)

cat("\nLargest projected decline:\n")
school_summary |> arrange(Change_PP) |> print(n = 10)

if (interactive() && !exists("config")) {
  View(school_summary)
  View(school_equity)
  View(opportunity)
}
