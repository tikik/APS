library(tidyverse)
library(dplyr)
#1. Import demographic data, named equity for short name. 
equity<- read_csv("C:/Users/t/OneDrive/Documents/APS/demographic.csv")

#2. Define student matching columns: this dataset has more than 19000 duplicated rows. 
keys <- c("Student ID", "Academic Year", "Student Grade")

#3. Clean spaces and missing values. using all_of vector charactor for consistency style use, instead of `` (backtick) for column names in tibble.
equity <- equity |>
  dplyr::select(
    all_of(keys), School, Enrolled, Sex, `Hispanic or Latino`, Race, `English Language Learner`
    ) |>
  dplyr::mutate(
    across(everything(), str_trim),
    across(everything(), ~ na_if(.x, ""))
  )

#4. Keep one demographic record per student-per-grade
equity_clean <- equity |>
  distinct(across(all_of(keys)), .keep_all= TRUE)

#5. Review Counts
cat("Original records: ", nrow(equity), "\n")
cat("Unique profiles: ", nrow(equity_clean), "\n")
cat("Excess records: ", nrow(equity)- nrow(equity_clean), "\n")

#6. Save
  # Define the output folder
  output_folder <- "C:/Users/t/OneDrive/Documents/APS/output"
  
  # Create the folder if it does not exist
  dir.create(output_folder, recursive = TRUE, showWarnings = FALSE)
  
  # Check that the folder exists
  dir.exists(output_folder)
  
  
  write_csv(
    equity_clean,
    file.path(output_folder, "equity_clean.csv")
  )
  View(equity_clean)


