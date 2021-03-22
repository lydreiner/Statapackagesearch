/* test code */
global rootdir "U:/Documents/AEA_Workspace/Statapackagesearch"
cap ssc install txttool
cap ssc install filelist

clear all

*Scans entire directory and stores output as 3 variables- we care about the second variable named "filename" which stores names of all do files 
filelist, directory("$rootdir") pat ("*.do")
drop dirname
drop fsize

* for each element of variable filename, read in the do file 
**problem- must start with empty dataset
foreach v in filename {
	infix str300 txtstring 1-300 using "$rootdir/`v'"


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


save "raw_data_parsed_`v'.dta", replace
}
*use for diagnostics- see lines where false positives occurred- do I need to change the cleaning? do I need to add something?
append using raw_data_parsed_`v'.dta, replace
 

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
