
library(tidyverse)

# 1. Load merged dataset
aps <- read_csv(
  "C:/Users/t/OneDrive/Documents/APS/01_aps_clean.csv",
  col_types = cols(`Student ID` = col_character()),
  show_col_types = FALSE
)

# 2. Select Grade 6 and classify achievement, identify who is Mid/Above
grade6 <- aps |>
  filter(`Student Grade` == 6) |>
  mutate(
    Score = as.numeric(`Overall Scale Score`),
    Mid_Above = case_when(
      `Overall Relative Placement` == "Mid or Above Grade Level" ~ 1,
      is.na(`Overall Relative Placement`) ~ NA_real_,
      TRUE ~ 0
    )
  )

grade6 |>
  group_by(`Academic Year`, `Norming Window`) |>
  summarise(
    Students = n(),
    Missing_Race = sum(is.na(Race)),
    Missing_Race_Pct = round(100 * mean(is.na(Race)), 1),
    .groups = "drop"
  )

grade6 |>
  group_by(
    `Academic Year`,
    `Hispanic or Latino`
  ) |>
  summarise(
    Records = n(),
    Missing_Race = sum(is.na(Race)),
    Missing_Pct = round(100 * mean(is.na(Race)), 1),
    .groups = "drop"
  )


# 3. Reusable statistical summary 
reading_stats <- function(df, ...) {
  df |>
    group_by(...) |>
    summarise(
      Students = n(),
      Mean = round(mean(Score, na.rm = TRUE), 1),
      Median = median(Score, na.rm = TRUE),
      Min = min(Score, na.rm = TRUE),
      Max = max(Score, na.rm = TRUE),
      SD = round(sd(Score, na.rm = TRUE), 1),
      Mid_Above_Count = sum(Mid_Above == 1, na.rm = TRUE),
      Valid_Placements = sum(!is.na(Mid_Above)),
      .groups = "drop"
    ) |>
    mutate(
      Mid_Above_Pct = round(
        100 * Mid_Above_Count / Valid_Placements, 1
      )
    )
}

# 4. Calculate district, school and equity statistics summaries for leadership presentation
district <- reading_stats(
  grade6, `Academic Year`, `Norming Window`
)

schools <- reading_stats(
  grade6, School, `Academic Year`, `Norming Window`
)

equity <- reading_stats(
  grade6, `Hispanic or Latino`, Race,
  `Academic Year`, `Norming Window`
)

# 5. Review results in R
View(district)
View(schools)
View(equity)

# 6. Export for Tableau
output <- "C:/Users/t/OneDrive/Documents/APS/output"

write_csv(district, file.path(output, "Grade6_District.csv"))
write_csv(schools, file.path(output, "Grade6_Schools.csv"))
write_csv(equity, file.path(output, "Grade6_Equity.csv"))