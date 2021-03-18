clear all
cap log close


log using "whatshot.log", replace
ssc whatshot, n(10000)
log close

import delimited whitespace rank hits packagename authors using "whatshot.log", rowrange(14:) delimiters("       ", collapse) clear

gen byte notnumeric = real(hits)==.
drop if notnumeric==1
drop authors-notnumeric
drop whitespace

destring rank, replace
destring hits, replace

label var rank "Package popularity (rank out of total # of packages)"


sum hits, detail
gen probFalsePos = rank/_N if _n>`r(p90)' 
* include prob of false positive if package is below 90th percentile
replace probFalsePos = 0 if _n<=`r(p90)'
label var probFalsePos "likelihood of false positive based on package popularity"

save "packagelist.dta", replace
