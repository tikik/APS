# 07_prediction_eval.R — Inference and IN-SAMPLE model diagnostics
# Depends on grade6 created in File 05; model/training created in File 06.
# Uses no hard-coded numerical results. This is NOT independent model validation.
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(readr))

if (!exists("grade6")) stop("File 07 needs 'grade6' from File 05; run via run_pipeline.R")
output <- if (exists("config")) config$paths$output else "output"
dir.create(output, showWarnings = FALSE, recursive = TRUE)

winter <- grade6 |>
  filter(`Academic Year` %in% c("2022-2023", "2023-2024"),
         Window == "Winter", !is.na(Mid_Above)) |>
  group_by(`Academic Year`) |>
  summarise(Success = sum(Mid_Above), Students = n(),
            Rate_Pct = round(100 * Success / Students, 2), .groups = "drop") |>
  arrange(`Academic Year`)
print(winter)
readr::write_csv(winter, file.path(output, "Grade6_Winter_Year_Comparison.csv"))
if (nrow(winter) == 2L && all(winter$Students > 0)) {
  ptest <- prop.test(x = winter$Success, n = winter$Students, correct = FALSE)
  print(ptest)
  readr::write_csv(tibble(Test = "Two independent Winter proportions",
                           Statistic = unname(ptest$statistic),
                           P_Value = ptest$p.value,
                           Difference_PP = round(100 * diff(winter$Rate_Pct) / 100, 2)),
                   file.path(output, "Grade6_Proportion_Test.csv"))
} else warning("Cannot run two-year proportion test: expected exactly two Winter cohorts")

# Build paired scores directly from source data, not from unverified object names.
paired <- grade6 |>
  filter(`Academic Year` == "2022-2023", Window %in% c("Winter", "Spring")) |>
  select(`Student ID`, Window, `Overall Scale Score`) |>
  mutate(Score = suppressWarnings(as.numeric(`Overall Scale Score`))) |>
  select(`Student ID`, Window, Score) |>
  tidyr::pivot_wider(names_from = Window, values_from = Score) |>
  filter(is.finite(Winter), is.finite(Spring))
if (nrow(paired) >= 2) {
  paired_test <- t.test(paired$Spring, paired$Winter, paired = TRUE)
  print(paired_test)
  readr::write_csv(tibble(Paired_Students = nrow(paired),
                           Mean_Growth = mean(paired$Spring - paired$Winter),
                           P_Value = paired_test$p.value),
                   file.path(output, "Grade6_Paired_Growth_Test.csv"))
} else warning("Too few matched students for paired growth test")

# Model fitted to training data in File 06: training-set-only performance.
if (exists("model") && exists("training") &&
    "Mid_Above_Spring" %in% names(training)) {
  predicted <- as.numeric(predict(model, newdata = training, type = "response"))
  actual <- as.numeric(training$Mid_Above_Spring)
  valid <- is.finite(predicted) & !is.na(actual) & actual %in% c(0, 1)
  if (any(valid)) {
    baseline <- mean(actual[valid])
    brier <- tibble(Method = c("Logistic regression (training set)",
                               "Constant prevalence (training set)"),
                    Brier_Score = c(mean((predicted[valid] - actual[valid])^2),
                                    mean((baseline - actual[valid])^2)),
                    N = sum(valid))
    print(brier)
    readr::write_csv(brier, file.path(output, "Grade6_Training_Brier.csv"))
  }
} else message("SKIP Brier score: File 06 did not provide 'training' and 'model'.")
