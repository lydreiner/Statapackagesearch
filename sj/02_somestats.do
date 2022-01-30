/* compute some stats */

include "config.do"
sjlog using 02_somestats, replace

use "https://github.com/AEADataEditor/Statapackagesearch.data/raw/main/aearep-stats.dta"
destring adocount docount dolines, replace

/* how many repositories */
distinct aearep
local naearep = r(ndistinct)

/* how many with Stata code */
keep if docount>0
distinct aearep
local naearepp = r(ndistinct)

/* sum up */
collapse (sum) sumado = adocount sumdo = docount sumlines = dolines (mean) adocount docount dolines


sjlog close

replace adocount=round(adocount)
replace docount =round(docount)
replace dolines =round(dolines)

local sumado   = sumado[1]
local sumdo    = sumdo[1]
local sumlines = sumlines[1]
local adocount = adocount[1]
local docount  = docount[1]
local dolines  = dolines[1]



/* output LaTeX strings */


file open strings using "appendixa_strings.tex", write text replace
file write strings  "\newcommand{\anaearep}{`naearep'}" _n
file write strings  "\newcommand{\anaearepp}{`naearepp'}" _n
file write strings  "\newcommand{\asumado}{`sumado'}" _n
file write strings  "\newcommand{\asumdo}{`sumdo'}" _n
file write strings  "\newcommand{\asumlines}{`sumlines'}" _n
file write strings  "\newcommand{\aadocount}{`adocount'}" _n
file write strings  "\newcommand{\adocount}{`docount'}" _n
file write strings  "\newcommand{\adolines}{`dolines'}" _n

file close strings
