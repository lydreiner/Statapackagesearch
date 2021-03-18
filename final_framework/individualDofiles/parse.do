** Parsing code for missing package match

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