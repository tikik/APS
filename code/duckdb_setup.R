
install.packages(c("DBI", "duckdb"))
library(DBI)
library(duckdb)


# create a local database:
con <- dbConnect (
  duckdb(), 
  dbdir = "APS.duckdb"
)

# Check connection:
dbGetQuery(con, "Select 1 As Test")
library(readr)

iready <- read_csv(
  "C:/Users/t/OneDrive/Documents/APS/iReady.csv",
  col_types = cols(.default = col_character()),
  show_col_types = FALSE
)

dbWriteTable(
  con,
  "iready",
  iready,
  overwrite = TRUE
)

#Confim records were loaded
dbGetQuery(con, "SELECT COUNT(*) AS Total_Records from iready")


window_audit <- dbGetQuery(con, "
  WITH attempts AS (
    SELECT
      \"Student ID\",
      \"Academic Year\",
      \"Student Grade\",
      \"Norming Window\",
      COUNT(*) AS Total_Attempts
    FROM iready
    GROUP BY
      \"Student ID\",
      \"Academic Year\",
      \"Student Grade\",
      \"Norming Window\"
  )

  SELECT
    \"Academic Year\",
    \"Norming Window\",
    COUNT(*) AS Assessment_Sets,
    SUM(CASE WHEN Total_Attempts > 1 THEN 1 ELSE 0 END)
      AS Sets_With_Multiple_Attempts,
    SUM(Total_Attempts - 1) AS Additional_Attempts
  FROM attempts
  GROUP BY \"Academic Year\", \"Norming Window\"
  ORDER BY \"Academic Year\", \"Norming Window\"
")

View(window_audit)


# Find student with multiple attempts: 


student_attempts <- dbGetQuery(con, "
  SELECT
    \"Student ID\",
    \"Student Grade\",
    \"Academic Year\",
    \"Norming Window\",
    COUNT(*) AS Total_Attempts,
    MIN(TRY_CAST(\"Overall Scale Score\" AS DOUBLE)) AS Min_Score,
    MAX(TRY_CAST(\"Overall Scale Score\" AS DOUBLE)) AS Max_Score
  FROM iready
  GROUP BY
    \"Student ID\", \"Student Grade\",
    \"Academic Year\", \"Norming Window\"
  HAVING COUNT(*) > 1
  ORDER BY \"Academic Year\", \"Norming Window\",
           Total_Attempts DESC
")

View(student_attempts)

#all attempts and their individual scores


student_details <- dbGetQuery(con, "
  SELECT
    i.\"Student ID\",
    i.\"Student Grade\",
    i.\"Academic Year\",
    i.\"Norming Window\",
    i.\"Overall Scale Score\",
    i.\"Overall Relative Placement\",
    d.Total_Attempts
  FROM iready AS i
  JOIN (
    SELECT
      \"Student ID\", \"Student Grade\",
      \"Academic Year\", \"Norming Window\",
      COUNT(*) AS Total_Attempts
    FROM iready
    GROUP BY
      \"Student ID\", \"Student Grade\",
      \"Academic Year\", \"Norming Window\"
    HAVING COUNT(*) > 1
  ) AS d
    ON i.\"Student ID\" = d.\"Student ID\"
   AND i.\"Student Grade\" = d.\"Student Grade\"
   AND i.\"Academic Year\" = d.\"Academic Year\"
   AND i.\"Norming Window\" = d.\"Norming Window\"
  ORDER BY
    i.\"Academic Year\",
    i.\"Norming Window\",
    i.\"Student ID\"
")

View(student_details)
