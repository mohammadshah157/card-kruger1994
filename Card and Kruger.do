clear all
set more off
/* 

This part is going to be used only if higher version of STATA is being used. 
I have to manually download the dataset from https://davidcard.berkeley.edu/data_sets/njmin.zip
because older version of STATA experiences Licensing issue. 

* Create temp directory macro correctly
local tempdir "`c(tmpdir)'"
* =============================================================================
* 1. Project Setup
* =============================================================================

cd "YOUR_WORKING_DIRECTORY"

capture mkdir output
capture mkdir tables


* =============================================================================
* 2. Load Data
* =============================================================================
*
* Download manually:
* https://davidcard.berkeley.edu/data_sets/njmin.zip
*
* Extract:
*   - public.dat
*   - codebook
*
* Place both files in working directory.
* =============================================================================

infix ///
    str5 sheet          1-5 ///
    byte chain          6 ///
    byte co_owned       7 ///
    byte state          8 ///
    byte southj         9 ///
    byte centralj      10 ///
    byte northj        11 ///
    byte pa1           12 ///
    byte pa2           13 ///
    byte shore         14 ///
    int  ncalls        15-16 ///
    float empft        17-21 ///
    float emppt        22-26 ///
    float nmgrs        27-30 ///
    float wage_st      31-35 ///
    int   inctime      36-37 ///
    int   firstinc     38-39 ///
    byte  bonus        40 ///
    float pctaff       41-45 ///
    float meals        46-50 ///
    float open         51-55 ///
    float hrsopen      56-60 ///
    float psoda        61-65 ///
    float pfry         66-70 ///
    float pentree      71-75 ///
    int   nregs        76-77 ///
    int   nregs11      78-79 ///
    byte  type2        80 ///
    byte  status2      81 ///
    int   date2        82-85 ///
    int   ncalls2      86-87 ///
    float empft2       88-92 ///
    float emppt2       93-97 ///
    float nmgrs2       98-101 ///
    float wage_st2    102-106 ///
    int   inctime2    107-108 ///
    int   firstin2    109-110 ///
    byte  special2    111 ///
    float meals2      112-116 ///
    float open2       117-121 ///
    float hrsopen2    122-126 ///
    float psoda2      127-131 ///
    float pfry2       132-136 ///
    float pentree2    137-141 ///
    int   nregs2      142-143 ///
    int   nregs112    144-145 ///
using public.dat, clear


save output/njmin_raw.dta, replace

*/

* =============================================================================
* 1. Import Clean Dataset
* =============================================================================

import delimited "fast-food-data.csv", clear


* =============================================================================
* 2. Variable Construction
* =============================================================================

gen NJ = (state == 1)

label define njlbl 0 "Pennsylvania" 1 "New Jersey"
label values NJ njlbl

destring empft emppt nmgrs empft2 emppt2 nmgrs2, replace force

* Full-Time Equivalent Employment
gen fte_pre  = empft  + nmgrs  + 0.5*emppt
gen fte_post = empft2 + nmgrs2 + 0.5*emppt2

* Change in employment
gen d_fte = fte_post - fte_pre


* Keep balanced observations
drop if missing(fte_pre, fte_post)


* Treatment intensity
gen gap = 0

replace gap = (5.05 - wage_st)/wage_st ///
    if NJ == 1 & wage_st < 5.05


* =============================================================================
* 3. Descriptive Statistics
* =============================================================================

tabstat fte_pre fte_post d_fte, ///
    by(NJ) ///
    statistics(mean sd n) ///
    columns(statistics)


* =============================================================================
* 4. Regression Analysis
* =============================================================================

capture ssc install estout

eststo clear

* Model 1
eststo m1: reg d_fte NJ

* Model 2
eststo m2: reg d_fte NJ i.chain co_owned

* Model 3
eststo m3: reg d_fte gap

* Model 4
eststo m4: reg d_fte gap i.chain co_owned


* =============================================================================
* 5. Regression Table
* =============================================================================

esttab m1 m2 m3 m4, ///
    se ///
    b(3) ///
    se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    label ///
    mtitles( ///
        "NJ Only" ///
        "NJ + Controls" ///
        "GAP Only" ///
        "GAP + Controls" ///
    ) ///
    stats(N r2, ///
        labels("Observations" "R-squared"))

