library(DBI)
library(duckdb)
library(tidyverse)

# 1. Import i-Ready data
iready <- read_csv(
  "C:/Users/t/OneDrive/Documents/APS/iReady.csv",
  col_types = cols(.default = col_character()),
  show_col_types = FALSE
)

# 2. Define assessment keys
keys <- c("Student ID", "Academic Year", "Student Grade")
assessment_keys <- c(keys, "Norming Window")

# 3. Prepare reading scores and clean keys
iready <- iready |>
  mutate(
    across(all_of(assessment_keys), str_trim),
    Score = as.numeric(`Overall Scale Score`)
  )

# 4. Assessment consistency check
assessment_audit <- iready |>
  count(across(all_of(assessment_keys)), name = "Total_Attempts") |>
  mutate(
    Additional_Attempts = Total_Attempts - 1,
    Needs_Review = Total_Attempts > 1
  )

cat("Total assessment records:", nrow(iready), "\n")
cat("Unique assessment sets:", nrow(assessment_audit), "\n")
cat("Assessment sets with multiple attempts:",
    sum(assessment_audit$Needs_Review), "\n")
cat("Additional assessment records:",
    sum(assessment_audit$Additional_Attempts), "\n")
cat("Students affected:",
    n_distinct(assessment_audit$`Student ID`[
      assessment_audit$Needs_Review
    ]), "\n")

# 5. Keep first valid assessment per window
iready_clean <- iready |>
  filter(!is.na(Score)) |>
  distinct(across(all_of(assessment_keys)), .keep_all = TRUE)

# 6. Review and export
cat("Selected assessment records:", nrow(iready_clean), "\n")

output_folder <- "C:/Users/t/OneDrive/Documents/APS/output"
dir.create(output_folder, showWarnings = FALSE)

write_csv(
  iready_clean,
  file.path(output_folder, "iready_clean.csv")
)

#7. See how many records with their total attemps beyond the first one. 
assessment_audit |> 
  count(Total_Attempts)


#8. Now I want to see which students have more than 3 assessments in 1 norming windoow of one academic year:
three_plus <- assessment_audit |>
  filter(Total_Attempts >= 3) |>
  arrange(desc(Total_Attempts))

View(three_plus)
three_plus_details <- iready |>
  inner_join(three_plus, by = assessment_keys) |>
  arrange(`Student ID`, `Academic Year`, `Norming Window`)
View(three_plus_details)

#BONUS: Window audit
#We can create an extra file for duckdb_setup.R but optional


# create a local database:
con <- dbConnect (
  duckdb(), 
  dbdir = "APS.duckdb"
)

# Check connection:
dbGetQuery(con, "Select 1 As Test")


