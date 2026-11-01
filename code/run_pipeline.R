# Run from the APS project root: source("run_pipeline.R")
suppressPackageStartupMessages(library(yaml))
config <- yaml::read_yaml("config.yml")
root <- normalizePath(config$project$root, mustWork = TRUE)
setwd(root)

input_files <- unlist(config$paths[c("input_assessments", "input_demographics")], use.names = FALSE)
missing_inputs <- input_files[!file.exists(input_files)]
if (length(missing_inputs)) stop("Missing input files: ", paste(missing_inputs, collapse = ", "))

dir.create(config$paths$output, recursive = TRUE, showWarnings = FALSE)
all_scripts <- unlist(config$pipeline$scripts, use.names = FALSE)
optional <- unlist(config$pipeline$optional_scripts, use.names = FALSE)
script_dir <- config$paths$scripts
# Shared environment: scripts 07 and 08 reuse results from scripts 05 and 06.
analysis_env <- new.env(parent = globalenv())
for (filename in all_scripts) {
  path <- file.path(script_dir, filename)
  if (!file.exists(path)) {
    if (filename %in% optional) { message("SKIP optional: ", path); next }
    stop("Required R script missing: ", path, ". Update config.yml to match exact filenames.")
  }
  message("RUN ", path)
  source(path, local = analysis_env, chdir = FALSE)
}
message("RUN 09_quality_checks.R")
source(file.path(script_dir, "09_quality_checks.R"), local = new.env(parent = globalenv()), chdir = FALSE)
message("Pipeline complete. Review results and disclosure flags before release.")
