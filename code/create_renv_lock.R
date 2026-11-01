# Run once in your existing APS RStudio project to create the REAL renv.lock.
# Do not fabricate lockfile versions; snapshot packages actually used by your project.
if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv")
renv::init(bare = TRUE)
# Install/check packages used in APS scripts if they aren't already installed.
required <- c("tidyverse", "yaml", "xtable")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) install.packages(missing)
renv::snapshot(prompt = FALSE)
message("Created renv.lock from the current R environment. Commit this file to GitHub.")
