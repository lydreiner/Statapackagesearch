/* test code */
include config.do
cap ssc install txttool

clear all
* read in the lines (max line length 300)
infix str300 txtstring 1-300 using "Tables_copy_test.do"
* indexes each line
gen line = _n
* drop blank lines
drop if txtstring == ""

/* clean - this might be handled by the stopword file as well */

* split on common delimiters- txttool can't handle long strings
replace txtstring = subinstr(txtstring,"\", " ",.)
replace txtstring = subinstr(txtstring,"{", " ",.)
replace txtstring = subinstr(txtstring,"}", " ",.)
replace txtstring = subinstr(txtstring,"="," ",.)
replace txtstring = subinstr(txtstring, "$"," ",.)
replace txtstring = subinstr(txtstring, "/"," ",.)
replace txtstring = subinstr(txtstring, "_"," ",.)
replace txtstring = subinstr(txtstring, "*"," ",.)
replace txtstring = subinstr(txtstring, "-"," ",.)
replace txtstring = subinstr(txtstring, ","," ",.)

* perform the txttool analysis
txttool txtstring, sub("signalcommands.txt") stop("stopwords.txt") gen(bagged)  bagwords prefix(w_)

save "raw_data_parsed.dta", replace
*use for diagnostics- see lines where false positives occurred- do I need to change the cleaning? do I need to add something?

*Shows count of each unique word and collapses into 1 observation
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
* somewhere in here the count gets dropped- why?

/* you might want to drop all words that are numbers */
*- ideally this is done using the stopwords file 

sort word

save "scanned_dofile.dta", replace
tempfile package_list 
use "package_list_dta.dta"
rename v1 word
sort word
save `package_list'
use "scanned_dofile.dta"
merge 1:1 word using `package_list' 
list if _merge==3


*match with the package names
*match by signal commands
* match by dependencies
* variable _merge created contains commonalities
