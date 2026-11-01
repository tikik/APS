
library(tidyverse)

# 1. Load cleaned assessments
grade6 <- read_csv(
  "C:/Users/t/OneDrive/Documents/APS/01_aps_clean.csv",
  col_types = cols(`Student ID` = col_character()),
  show_col_types = FALSE
) |>
  filter(`Student Grade` == 6) |>
  mutate(
    Window = str_extract(`Norming Window`, "Fall|Winter|Spring"),
    Score = as.numeric(`Overall Scale Score`),
    Mid_Above = as.integer(
      `Overall Relative Placement` == "Mid or Above Grade Level"
    )
  )

# 2. Match historical Winter and Spring assessments
training <- grade6 |>
  filter(`Academic Year` == "2022-2023",
         Window %in% c("Winter", "Spring")) |>
  select(`Student ID`, Window, Score, Mid_Above) |>
  pivot_wider(
    names_from = Window,
    values_from = c(Score, Mid_Above)
  ) |>
  filter(!is.na(Score_Winter), !is.na(Mid_Above_Spring))

# 3. Fit logistic regression
model <- glm(
  Mid_Above_Spring ~ Score_Winter,
  data = training,
  family = binomial()
)

summary(model)

# 4. Predict Spring achievement for current students
predictions <- grade6 |>
  filter(`Academic Year` == "2023-2024",
         Window == "Winter", !is.na(Score)) |>
  mutate(
    Probability = predict(model, newdata = data.frame(
      Score_Winter = Score
    ), type = "response")
  )

# 5. Summarize forecasts
district_prediction <- predictions |>
  summarise(
    Students = n(),
    Projected_EOY_Pct = round(100 * mean(Probability), 1)
  )

school_prediction <- predictions |>
  group_by(School) |>
  summarise(
    Students = n(),
    Projected_EOY_Pct = round(100 * mean(Probability), 1),
    .groups = "drop"
  )

View(district_prediction)
View(school_prediction)

# 6. Export school forecasts
write_csv(
  school_prediction,
  "C:/Users/t/OneDrive/Documents/APS/output/Grade6_Logistic_Forecast.csv"
)


equity_forecast |>
  mutate(
    Missing_Probability = Students - Students_With_Probability,
    Coverage_Pct = round(
      100 * Students_With_Probability / Students, 1
    )
  ) |>
  select(
    Equity_Group, Students,
    Students_With_Probability,
    Missing_Probability, Coverage_Pct
  ) |>
  View()



library(tidyverse)

# 1. Load cleaned assessments
grade6 <- read_csv(
  "C:/Users/t/OneDrive/Documents/APS/01_aps_clean.csv",
  col_types = cols(`Student ID` = col_character()),
  show_col_types = FALSE
) |>
  filter(`Student Grade` == 6) |>
  mutate(
    Window = str_extract(`Norming Window`, "Fall|Winter|Spring"),
    Score = as.numeric(`Overall Scale Score`),
    Mid_Above = as.integer(
      `Overall Relative Placement` == "Mid or Above Grade Level"
    )
  )

# 2. Match historical Winter and Spring assessments
training <- grade6 |>
  filter(`Academic Year` == "2022-2023",
         Window %in% c("Winter", "Spring")) |>
  select(`Student ID`, Window, Score, Mid_Above) |>
  pivot_wider(
    names_from = Window,
    values_from = c(Score, Mid_Above)
  ) |>
  filter(!is.na(Score_Winter), !is.na(Mid_Above_Spring))

# 3. Fit logistic regression
model <- glm(
  Mid_Above_Spring ~ Score_Winter,
  data = training,
  family = binomial()
)

summary(model)

# 4. Predict Spring achievement for current students
predictions <- grade6 |>
  filter(`Academic Year` == "2023-2024",
         Window == "Winter", !is.na(Score)) |>
  mutate(
    Probability = predict(model, newdata = data.frame(
      Score_Winter = Score
    ), type = "response")
  )

# 5. Summarize forecasts
district_prediction <- predictions |>
  summarise(
    Students = n(),
    Projected_EOY_Pct = round(100 * mean(Probability), 1)
  )

school_prediction <- predictions |>
  group_by(School) |>
  summarise(
    Students = n(),
    Projected_EOY_Pct = round(100 * mean(Probability), 1),
    .groups = "drop"
  )

View(district_prediction)
View(school_prediction)

# 6. Export school forecasts
write_csv(
  school_prediction,
  "C:/Users/t/OneDrive/Documents/APS/output/Grade6_Logistic_Forecast.csv"
)
