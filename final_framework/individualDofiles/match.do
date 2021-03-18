** Matching code

**Inputs: parsed .dta files from parse.do and list of ssc packages

** Outputs: list of missing packages


 *List all generated .dta files and append them to prepare for the match
 fs "$codedir/parsed_data_*.dta"
 append using `r(files)'
 
 
*Collapses unique words into 1 observation
collapse (sum) w_* 

* create a new var and count to capture frequency
gen word = ""
gen count = 0

*expand datset again
global counter 0
foreach var of varlist w_* {
	/* add a row for the next variable */
	global counter = $counter +1
	set obs $counter
	/* capture word and its count */
    
	*capture the name of the variable and its frequency and do this for every variable, then drop all variables (collapses the unique variables)
	replace word = "`var'" if _n == $counter
	replace count = `var'  if _n == $counter
}
replace word = subinstr(word,"w_","",.)
drop w_*

/* you might want to drop all words that are numbers */
*- ideally this is done using the stopwords file 

sort word

// Merge/match
save "scanned_dofile.dta", replace
tempfile package_list 
use "$rootdir/packagelist_cleaned.dta"
rename package word
sort word
save `package_list'
use "scanned_dofile.dta"
merge 1:1 word using `package_list' 
list if _merge==3


// Set up output export
gen matchedpackage = word if _merge==3
label var matchedpackage "(Potential) missing package found"
keep if matchedpackage !=""

// Sort by rank (incorporates false positive probability) from packagelist file
gsort rank matchedpackage

// Export missing package list to .csv
export excel matchedpackage rank probFalsePos using "$rootdir/missingpackages.xlsx", firstrow(varlabels) keepcellfmt replace

// Cleanup
local datafiles : dir "$codedir" files "parsed_data_*.dta"

foreach v in `datafiles' {
erase "`v'"
}