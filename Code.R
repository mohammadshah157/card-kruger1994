# Replication: Card & Krueger (1994)
# "Minimum Wages and Employment: A Case Study of the Fast-Food Industry in New Jersey and Pennsylvania"
# American Economic Review, 84(4), 772-793

# Method: Difference-in-Differences (DiD)
# Treatment: New Jersey minimum wage increase from $4.25 → $5.05 (April 1992)
# Control:   Pennsylvania (no wage change)
# Outcome:   Full-Time Equivalent (FTE) Employment in Fast-Food Restaurants

# Package Installation  

# install.packages(c("tidyverse", "haven", "modelsummary",
#                    "knitr", "kableExtra", "dplyr", "readr", "plm"))


# Load Libraries 

library(tidyverse)      # Data wrangling & ggplot2
library(haven)          # Read Stata/SAS/SPSS files
library(modelsummary)   # Publication-quality regression tables
library(knitr)          # Table rendering
library(kableExtra)     # Extended kable formatting
library(dplyr)          # Data manipulation
library(readr)          # Fast file reading
library(plm)            # Panel data models


# Data Acquisition 
# Source: David Card's replication archive (UC Berkeley)
# The dataset contains survey responses from ~400 fast-food restaurants collected before (Feb–Mar 1992) and after (Nov–Dec 1992) the wage increase.

temp_zip <- tempfile(fileext = ".zip")
temp_dir <- tempdir()

download.file(
  url     = "http://davidcard.berkeley.edu/data_sets/njmin.zip",
  destfile = temp_zip,
  mode    = "wb"
)
unzip(temp_zip, exdir = temp_dir)


# Parse Codebook & Load Raw Data 
# The codebook (plain text) contains variable names starting at line 8.
# Lines corresponding to blank separators are dropped before extracting names.

codebook <- read_lines(file.path(temp_dir, "codebook"))

variable_names <- codebook[8:59] %>%           # Relevant lines
  .[-c(5, 6, 13, 14, 32, 33)] %>%             # Drop blank / separator lines
  str_sub(1, 13) %>%                            # Variable name occupies first 13 chars
  str_squish() %>%                              # Remove extra whitespace
  str_to_lower()                                # Standardise to lowercase

dataset <- read_table(
  file      = file.path(temp_dir, "public.dat"),
  col_names = FALSE
)

dataset <- dataset %>%
  select(-X47) %>%                             # Drop trailing empty column
  setNames(variable_names) %>%                 # Apply parsed column names
  mutate(across(everything(), as.numeric)) %>% # Coerce all columns to numeric
  mutate(sheet = as.character(sheet))          # Sheet ID kept as character

# Save a clean CSV for reference / reuse
write.csv(dataset, file = "fast-food-data.csv", row.names = FALSE)


# Variable Construction 

# FTE Employment = Full-time workers + Managers + 0.5 × Part-time workers
#   (Card & Krueger 1994, Table 3 footnote)
#
# GAP variable measures how far below $5.05 a store's starting wage was
# before the increase; zero for Pennsylvania stores (unaffected).
# It captures the *intensity* of the treatment at the store level.

dataset <- dataset %>%
  mutate(
    # Treatment indicator 
    NJ = ifelse(state == 1, 1, 0),             # 1 = New Jersey, 0 = Pennsylvania
    
    # Full-Time Equivalent employment 
    fte_pre  = empft  + nmgrs  + 0.5 * emppt,  # Wave 1 (before increase)
    fte_post = empft2 + nmgrs2 + 0.5 * emppt2, # Wave 2 (after increase)
    
    # Change in FTE (DiD outcome variable) 

    d_fte = fte_post - fte_pre
  ) %>%
  filter(!is.na(fte_pre), !is.na(fte_post))   # Keep only balanced observations


# Descriptive Statistics (Table 3 Replication) 
# Compute group means and standard errors by state (NJ vs PA)

summary_stats <- dataset %>%
  group_by(NJ) %>%
  summarise(
    fte_pre_mean  = mean(fte_pre,  na.rm = TRUE),
    fte_pre_se    = sd(fte_pre,    na.rm = TRUE) / sqrt(n()),
    
    fte_post_mean = mean(fte_post, na.rm = TRUE),
    fte_post_se   = sd(fte_post,   na.rm = TRUE) / sqrt(n()),
    
    d_fte_mean    = mean(d_fte,    na.rm = TRUE),
    d_fte_se      = sd(d_fte,      na.rm = TRUE) / sqrt(n()),
    
    .groups = "drop"
  )

nj_stats <- summary_stats %>% filter(NJ == 1)
pa_stats <- summary_stats %>% filter(NJ == 0)

# Construct Table 3 in Card & Krueger format
table_3 <- data.frame(
  Variable = c(
    "FTE Employment — Before",
    "FTE Employment — After",
    "Change in FTE Employment"
  ),
  
  # Pennsylvania (control group)
  PA_Mean = c(pa_stats$fte_pre_mean, pa_stats$fte_post_mean, pa_stats$d_fte_mean),
  PA_SE   = c(pa_stats$fte_pre_se,   pa_stats$fte_post_se,   pa_stats$d_fte_se),
  
  # New Jersey (treatment group)
  NJ_Mean = c(nj_stats$fte_pre_mean, nj_stats$fte_post_mean, nj_stats$d_fte_mean),
  NJ_SE   = c(nj_stats$fte_pre_se,   nj_stats$fte_post_se,   nj_stats$d_fte_se),
  
  # Difference-in-Differences: NJ minus PA
  DiD_Mean = c(
    nj_stats$fte_pre_mean  - pa_stats$fte_pre_mean,
    nj_stats$fte_post_mean - pa_stats$fte_post_mean,
    nj_stats$d_fte_mean    - pa_stats$d_fte_mean
  ),
  DiD_SE = c(
    sqrt(nj_stats$fte_pre_se^2  + pa_stats$fte_pre_se^2),
    sqrt(nj_stats$fte_post_se^2 + pa_stats$fte_post_se^2),
    sqrt(nj_stats$d_fte_se^2    + pa_stats$d_fte_se^2)
  )
)

# Render Table 3
kable(
  table_3,
  digits  = 2,
  col.names = c("Variable", "Mean", "SE", "Mean", "SE", "Mean", "SE"),
  caption = "Table 3 — Mean FTE Employment by State and Period"
) %>%
  add_header_above(
    c(" " = 1, "Pennsylvania (Control)" = 2,
      "New Jersey (Treatment)" = 2, "NJ − PA (DiD)" = 2)
  ) %>%
  kable_classic(full_width = FALSE, html_font = "Cambria")


# Regression Analysis 
# We estimate four OLS specifications:
#
#   Model 1: ΔFte = α + β·NJ + ε
#             Bare DiD — NJ dummy captures the average treatment effect.
#
#   Model 2: ΔFte = α + β·NJ + γ·Chain + δ·CoOwned + ε
#             DiD with controls for chain fixed effects and ownership type.
#
#   Model 3: ΔFte = α + β·GAP + ε
#             GAP replaces the binary NJ indicator with a continuous measure
#             of treatment intensity (distance below the new wage floor).
#
#   Model 4: ΔFte = α + β·GAP + γ·Chain + δ·CoOwned + ε
#             Full specification combining GAP with store-level controls.


# GAP variable (treatment intensity) 
dataset <- dataset %>%
  mutate(
    gap = ifelse(
      NJ == 1 & wage_st < 5.05,
      (5.05 - wage_st) / wage_st,   # Proportional shortfall from new minimum
      0                              # Zero for PA stores and NJ stores already compliant
    )
  )


# Estimate models 

model1 <- lm(d_fte ~ NJ,                              data = dataset)
model2 <- lm(d_fte ~ NJ  + factor(chain) + co_owned,  data = dataset)
model3 <- lm(d_fte ~ gap,                              data = dataset)
model4 <- lm(d_fte ~ gap + factor(chain) + co_owned,  data = dataset)


# Regression table 

modelsummary(
  models = list(
    "(1) NJ Only"      = model1,
    "(2) NJ + Controls"= model2,
    "(3) GAP Only"     = model3,
    "(4) GAP + Controls"= model4
  ),
  stars       = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  coef_rename = c(
    "NJ"       = "New Jersey (Treatment)",
    "gap"      = "GAP (Treatment Intensity)",
    "co_owned" = "Company-Owned"
  ),
  gof_omit    = "AIC|BIC|Log|F",
  title       = "Table 4 — OLS Estimates of Change in FTE Employment",
  notes       = list(
    "Standard errors in parentheses.",
    "* p < 0.10, ** p < 0.05, *** p < 0.01",
    "Chain fixed effects included where noted (Burger King, KFC, Roy Rogers, Wendy's).",
    "GAP = max(0, (5.05 − starting wage) / starting wage) for NJ stores; 0 otherwise."
  ),
  output      = "kableExtra"
)
