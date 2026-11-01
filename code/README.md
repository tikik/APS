# APS Grade 6 Reading Achievement & Equity Analysis

Independent analytical work sample using Grade 6 i-Ready reading assessment and demographic data from academic years 2022–23 and 2023–24. **Not an official APS report.**

## Purpose

- Compare observed Mid or Above Grade Level reading achievement across assessment windows and student groups.
- Estimate Spring 2023–24 attainment from Winter results.
- Identify school-level trends and Early On Grade Level students for instructional review.
- Document data reconciliation, forecast limitations, and quality checks.

## Tools

R, tidyverse, DuckDB/DBI, Tableau, and YAML configuration.

## Project files

| File | Role |
|---|---|
| `01_equity_clean.R` | Clean and deduplicate demographic profiles |
| `02_iready_clean.R` | Review repeated assessments and select records |
| `03_merge_data.R` | Join assessments to demographics |
| `04_descriptive_stats.R` | District, school, and equity summaries |
| `05_grade6_forecast.R` | Historical Winter-to-Spring transition forecast |
| `06_logistic_regression.R` | Alternative logistic forecast |
| `07_prediction_eval.R` | Model diagnostics; existing training-set results are **not** independent validation |
| `08_grade6_equity_opportunities.R` | School populations, equity, and Early On opportunities |
| `09_quality_checks.R` | Reconciliation, range, coverage, and disclosure flags |
| `config.yml` | File paths and pipeline options |
| `run_pipeline.R` | Run scripts in sequence |
| `DATA_DECISION_LOG.md` | Document methods, decisions, and unresolved checks |

**Note:** Verify the exact script names in `config.yml`. Earlier local versions also used `09_equity_opportunities.R` and `08_statistical_validation.R`; use the names actually present in your project.

## Run in RStudio

1. Open the APS project directory in RStudio.
2. Install required R packages if missing:

   ```r
   install.packages(c("tidyverse", "readr", "dplyr", "DBI", "duckdb", "yaml"))
   ```

3. Place **authorized** input CSVs at the locations set in `config.yml` (`iReady.csv` and `equity.csv` in the current local setup).
4. Check `config.yml` paths and script filenames; do not move scripts unless you also update those paths.
5. Run:

   ```r
   source("run_pipeline.R")
   ```

6. Inspect the `output/` CSVs, console warnings, and quality-check results. Reconnect Tableau data sources to those outputs if needed.

## Main outputs

- `Grade6_District.csv`, `Grade6_Schools.csv`, `Grade6_Equity.csv`
- `Grade6_Forecast.csv`, `Grade6_School_Forecast.csv`, `Grade6_School_Comparison.csv`
- `Grade6_Trend_With_Forecast.csv`, `Grade6_Logistic_Forecast.csv`
- `Grade6_School_Population.csv`, `Grade6_School_Complete.csv`
- `Grade6_School_Equity_Forecast.csv`, `Grade6_Near_Benchmark.csv`

## Selected findings

- Winter 2023–24 Mid/Above: **14.9%** of 2,207 assessed Grade 6 records.
- Spring 2023–24 transition-model projection: **17.1%**; previous Spring observed: **17.5%**.
- The latest pipeline reported **46,135** selected assessment records, **zero** unmatched assessment records, **zero** automated QA failures, and **two** small-cell review flags.

## Interpretation and privacy

Forecasts are **estimates, not observed Spring results**. The transition and logistic models have not demonstrated independent predictive validity. Duplicate-attempt selection and CSV parsing warnings require further audit. School comparisons should account for cohort size and differing students across years.

**Never commit or publish student-level data**, the DuckDB database containing such records, or unsuppressed sensitive small-cell outputs. Share code, documentation, and approved synthetic or disclosure-reviewed aggregate data only. Confirm that APS permits public release of assignment-derived material before making this repository public.

## Documentation

See `DATA_DECISION_LOG.md` for assumptions and reconciliation decisions. The Tableau workbook contains the visualizations, but may require reconnection to locally generated CSV files.
