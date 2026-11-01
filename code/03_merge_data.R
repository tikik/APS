
library(tidyverse)

# 1. Load cleaned datasets
iready_clean <- read_csv(
  "C:/Users/t/OneDrive/Documents/APS/output/iready_clean.csv",
  show_col_types = FALSE,
  col_types = cols(`Student ID` = col_character())
)

equity_clean <- read_csv(
  "C:/Users/t/OneDrive/Documents/APS/output/equity_clean.csv",
  show_col_types = FALSE,
  col_types = cols(`Student ID` = col_character())
)

# 2. Define matching keys
keys <- c("Student ID", "Academic Year", "Student Grade")

# 3. Merge assessments with demographics
aps <- iready_clean |>
  left_join(equity_clean, by = keys)

# 4. Verify merge
cat("i-Ready records:", nrow(iready_clean), "\n")
cat("Merged records:", nrow(aps), "\n")
cat("Unmatched assessments:",
    sum(is.na(aps$School)), "\n")

# 5. Save merged dataset
write_csv(
  aps,
  "C:/Users/t/OneDrive/Documents/APS/01_aps_clean.csv"
)

#6. Important! SAfety check
stopifnot(nrow(aps) == nrow(iready_clean))


