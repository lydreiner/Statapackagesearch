** Master file for text-mining based package search

***************************
* Step 1: Preliminaries   *
***************************
clear all

// Set globals below

// Point to location of "final_framework" folder which contains scanning code, package list, and stopwords & subwords files
global rootdir "U:/Documents/AEA_Workspace/Statapackagesearch/final_framework/code"

// Point to location of folder with .do files to scan:
global codedir "U:/Documents/AEA_Workspace/aearep-994\119684\CODE"
cd "$codedir"


// Install packages, provide system info
local pwd : pwd

/* It will provide some info about how and when the program was run */
/* See https://www.stata.com/manuals13/pcreturn.pdf#pcreturn */
local variant = cond(c(MP),"MP",cond(c(SE),"SE",c(flavor)) )  
// alternatively, you could use 
// local variant = cond(c(stata_version)>13,c(real_flavor),"NA")  

di "=== SYSTEM DIAGNOSTICS ==="
di "Stata version: `c(stata_version)'"
di "Updated as of: `c(born_date)'"
di "Variant:       `variant'"
di "Processors:    `c(processors)'"
di "OS:            `c(os)' `c(osdtl)'"
di "Machine type:  `c(machine_type)'"
di "=========================="


/* install any packages locally */
capture mkdir "$rootdir/ado"
sysdir set PERSONAL "$rootdir/ado/personal"
sysdir set PLUS     "$rootdir/ado/plus"
sysdir set SITE     "$rootdir/ado/site"
sysdir

/* add necessary packages to perform the scan & analysis to the macro */

* *** Add required packages from SSC to this list ***
    local ssc_packages "fs txttool"
    // local ssc_packages "estout boottest"
    
    if !missing("`ssc_packages'") {
        foreach pkg in `ssc_packages' {
            dis "Installing `pkg'"
            ssc install `pkg', replace
        }
    }

/* after installing all packages, it may be necessary to issue the mata mlib index command */
	mata: mata mlib index


set more off

********************************************************
* Step 2: Collect list of all packages hosted at SSC   *
********************************************************
cap log close

// Collect top hits at SSC for the past month 
log using "whatshot.log", replace
* if the # of available packages ever exceeds 10000, adjust the line below
ssc whatshot, n(10000)
log close

// Data cleaning (import log file, export cleaned .dta file)

*May need to adjust the starting value for rowrange- target the first line where a package is mentioned
import delimited whitespace rank hits packagename authors using "whatshot.log", rowrange(14:) delimiters("       ", collapse) clear

gen byte notnumeric = real(hits)==.
drop if notnumeric==1
drop authors-notnumeric
drop whitespace

destring rank, replace
destring hits, replace

label var rank "Package popularity (rank out of total # of packages)"

// Develop ranking system to help determine likelihood of false positives
sum hits, detail

* include prob of false positive if # of monthly hits for the package is below 90th percentile
gen probFalsePos = rank/_N if _n>`r(p90)' 
replace probFalsePos = 0 if _n<=`r(p90)'
label var probFalsePos "likelihood of false positive based on package popularity"

save "packagelist.dta", replace

// If you wish to create a log file of the parsing/matching process, uncomment the section below
/*
global logdir "${rootdir}/logs"
cap mkdir "$logdir"

local c_date = c(current_date)
local cdate = subinstr("`c_date'", " ", "_", .)
local c_time = c(current_time)
local ctime = subinstr("`c_time'", ":", "_", .)

log using "$logdir/logfile_`cdate'-`ctime'.log", replace text
*/

***************************
* Step 3: Parsing	      *
***************************

*Parse each .do file in a directory, then append the parsed files

local files : dir "$codedir" files "*.do"

* Read in each do file in the folder and split by line
foreach v in `files' {
	di "`v'"

	infix str300 txtstring 1-300 using "$codedir/`v'", clear

* indexes each line
gen line = _n
* drop blank lines
drop if txtstring == ""


*drop comments if the // occurs at the start of the line
drop if regexm(txtstring,"^//")==1

*cannot drop comments/lines using regexm because the asterisk is an operator in the command (doesn't work')
drop if regexm(txtstring,"^/\*")==1
drop if regexm(txtstring,"^\*")==1

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


* perform the txttool analysis- removes stopwords and duplicates
txttool txtstring, sub("$rootdir/signalcommands.txt") stop("$rootdir/stopwords.txt") gen(bagged_words) bagwords prefix(w_)

* saves the results as .dta file (one for each .do file in the folder)
save "$codedir/parsed_data_`v'.dta", replace
 }

**********************
* Step 4: Matching 	 *
**********************

** Inputs: parsed .dta files from parsing code and list of freshly obtained ssc packages

** Outputs: list of missing packages


 *List all generated .dta files and append them to prepare for the match
 fs "parsed_data*.dta"
 append using `r(files)'
 
 
*Collapses unique words into 1 observation
collapse (sum) w_* 

* create a new var and count to capture frequency
gen word = ""
gen count = 0

*expand dataset again
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

sort word

// Cleanup
local datafiles : dir "$codedir" files "parsed_data_*.dta"

foreach v in `datafiles' {
erase "`v'"
}


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

// More cleanup
erase "scanned_dofile.dta"

**************************************************************************
* Step 5: Export output & install found missing packages (if desired) 	 *
**************************************************************************

// Set up output export
gen matchedpackage = word if _merge==3
label var matchedpackage "(Potential) missing package found"
keep if matchedpackage !=""

// Sort by rank (incorporates false positive probability) from packagelist file
gsort rank matchedpackage

// Export missing package list to Excel
export excel matchedpackage rank probFalsePos using "$rootdir/missingpackages.xlsx", firstrow(varlabels) keepcellfmt replace

// Uncomment the section below to install all packages found by the match
** Warning: Will install all packages found, including false positives!

/*
levelsof matchedpackage, clean local(foundpackages)
    if !missing("foundpackages") {
        foreach pkg in `foundpackages' {
            dis "Installing `pkg'"
            ssc install `pkg', replace
        }
    }


