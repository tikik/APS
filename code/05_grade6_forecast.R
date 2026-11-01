
library(tidyverse)

output <- "C:/Users/t/OneDrive/Documents/APS/output"

# 1. Load Grade 6 data
grade6 <- read_csv(
  "C:/Users/t/OneDrive/Documents/APS/01_aps_clean.csv",
  col_types = cols(`Student ID` = col_character()),
  show_col_types = FALSE
) |>
  filter(`Student Grade` == 6) |>
  mutate(
    Window = str_extract(`Norming Window`, "Fall|Winter|Spring"),
    Mid_Above = as.integer(
      `Overall Relative Placement` == "Mid or Above Grade Level"
    ),
    Equity_Group = case_when(
      `Hispanic or Latino` == "Y" ~ "Hispanic or Latino",
      `Hispanic or Latino` == "N" &
        Race == "Black or African American" ~ "Black (Non-Hispanic)",
      `Hispanic or Latino` == "N" & !is.na(Race) ~ "Other",
      TRUE ~ "Unknown"
    )
  )

# 2. Match historical Winter and Spring assessments
historical <- grade6 |>
  filter(
    `Academic Year` == "2022-2023",
    Window %in% c("Winter", "Spring")
  ) |>
  dplyr::select(
    `Student ID`, Window,
    `Overall Relative Placement`, Mid_Above
  ) |>
  pivot_wider(
    names_from = Window,
    values_from = c(`Overall Relative Placement`, Mid_Above)
  ) |>
  filter(
    !is.na(`Overall Relative Placement_Winter`),
    !is.na(Mid_Above_Spring)
  )

# 3. Historical transition probabilities
transitions <- historical |>
  group_by(`Overall Relative Placement_Winter`) |>
  summarise(
    Historical_Students = n(),
    Spring_Mid_Above = sum(Mid_Above_Spring),
    Probability = Spring_Mid_Above / Historical_Students,
    .groups = "drop"
  )

# 4. Apply historical probabilities to Winter 2023-24
forecast <- grade6 |>
  filter(
    `Academic Year` == "2023-2024",
    Window == "Winter"
  ) |>
  left_join(
    transitions,
    by = c(
      "Overall Relative Placement" =
        "Overall Relative Placement_Winter"
    )
  )

# Review records without a forecast probability
missing_forecast <- forecast |>
  filter(is.na(Probability))

cat("Students without forecast:", nrow(missing_forecast), "\n")

# 5. Forecast by equity group
equity_forecast <- forecast |>
  group_by(Equity_Group) |>
  summarise(
    Students = n(),
    Students_With_Probability = sum(!is.na(Probability)),
    Expected_Mid_Above = sum(Probability, na.rm = TRUE),
    Projected_EOY_Pct = round(
      100 * mean(Probability, na.rm = TRUE), 1
    ),
    .groups = "drop"
  )

write_csv(
  equity_forecast,
  file.path(output, "Grade6_Forecast.csv")
)

# 6. Forecast by school
school_forecast <- forecast |>
  group_by(School) |>
  summarise(
    Students = n(),
    Students_With_Probability = sum(!is.na(Probability)),
    Projected_EOY_Pct = round(
      100 * mean(Probability, na.rm = TRUE), 1
    ),
    .groups = "drop"
  )

write_csv(
  school_forecast,
  file.path(output, "Grade6_School_Forecast.csv")
)

# 7. Compare with actual Spring 2022-23
previous_spring <- grade6 |>
  filter(
    `Academic Year` == "2022-2023",
    Window == "Spring",
    !is.na(Mid_Above)
  ) |>
  group_by(School) |>
  summarise(
    Previous_Students = n(),
    Previous_EOY_Pct = round(
      100 * mean(Mid_Above), 1
    ),
    .groups = "drop"
  )

school_comparison <- school_forecast |>
  left_join(previous_spring, by = "School") |>
  mutate(
    Change_PP = round(
      Projected_EOY_Pct - Previous_EOY_Pct, 1
    )
  )

write_csv(
  school_comparison,
  file.path(output, "Grade6_School_Comparison.csv")
)

# 8. District trend: observed + projected
district <- read_csv(
  file.path(output, "Grade6_District.csv"),
  show_col_types = FALSE
)

district_forecast <- round(
  100 * mean(forecast$Probability, na.rm = TRUE), 1
)

trend <- district |>
  mutate(
    Window = str_extract(`Norming Window`, "Fall|Winter|Spring"),
    Status = "Observed"
  ) |>
  dplyr::select(
    `Academic Year`, Window, Mid_Above_Pct, Status
  ) |>
  bind_rows(
    tibble(
      `Academic Year` = "2023-2024",
      Window = "Spring",
      Mid_Above_Pct = district_forecast,
      Status = "Projected"
    )
  ) |>
  mutate(
    Period = case_when(
      `Academic Year` == "2022-2023" & Window == "Fall" ~ 1,
      `Academic Year` == "2022-2023" & Window == "Winter" ~ 2,
      `Academic Year` == "2022-2023" & Window == "Spring" ~ 3,
      `Academic Year` == "2023-2024" & Window == "Fall" ~ 4,
      `Academic Year` == "2023-2024" & Window == "Winter" ~ 5,
      `Academic Year` == "2023-2024" & Window == "Spring" ~ 6
    )
  ) |>
  arrange(Period)

write_csv(
  trend,
  file.path(output, "Grade6_Trend_With_Forecast.csv")
)

# 9. Review
View(transitions)
View(equity_forecast)
View(school_comparison)
View(trend)
