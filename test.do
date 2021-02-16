/* test code */

ssc install txttool

clear
infix str300 txtstring 1-300 using "lotsofmissingpackages.do"
gen line = _n
drop if txtstring == ""

/* clean - this might be handled by the stopword file as well */
replace txtstring = subinstr(txtstring,"\", " ",.)
replace txtstring = subinstr(txtstring,"{", " ",.)
replace txtstring = subinstr(txtstring,"}", " ",.)
replace txtstring = subinstr(txtstring,"="," ",.)


txttool txtstring, gen(bagged)  bagwords prefix(w_)

collapse (sum) w_* 

gen word = ""
gen count = 0
global counter 0
foreach var of varlist w_* {
	/* add a row for the next variable */
	global counter = $counter +1
	set obs $counter
	/* capture word and its count */
    replace word = "`var'" if _n == $counter
	replace count = `var'  if _n == $counter
}
replace word = subinstr(word,"w_","",.)
drop w_*

/* you might want to drop all words that are numbers */





