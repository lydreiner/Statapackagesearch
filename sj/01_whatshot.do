* whatshot.do
set more off
capture log close

sjlog using 01_whatshot.log, replace
sjlog close, replace

tempfile whatshot

log using "`whatshot'", name(whatshot) replace text
* if the # of available packages ever exceeds 10000, adjust the line below
n ssc whatshot
log close whatshot

// Data cleaning (import log file)

import delimited whitespace rank hits packagename authors using "`whatshot'", rowrange(14:) delimiters("       ", collapse) clear

gen byte notnumeric = real(hits)==.
drop if notnumeric==1
destring rank, replace
destring hits, replace

keep if rank < 11
qui sum hits
local hits = r(sum)

// get date

infile str200 string  using "`whatshot'",  clear
local month = string[43]
local year  = string[44]

// write out for LaTeX by hand

file open strings using "whatshot_strings.tex", write text replace
file write strings  "\newcommand{\whhits}{`hits'}" _n
file write strings  "\newcommand{\whmonth}{`month'}" _n
file write strings  "\newcommand{\whyear}{`year'}" _n
file close strings


*exit
