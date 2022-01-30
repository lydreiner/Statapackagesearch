/* compute some stats */

include "config.do"
sjlog using 03_comparedomain, replace

use "https://github.com/AEADataEditor/Statapackagesearch.data/raw/main/p_stats_econ.dta"
rename rank econ
tempfile econ
save `econ'

net install packagesearch, from("https://raw.githubusercontent.com/AEADataEditor/Statapackagesearch/main/") replace
p_whatshot, vars(rank hits)
rename rank whatshot

sort packagename
merge 1:1 packagename using `econ'
preserve
sort econ
keep if econ < 11
li packagename econ whatshot
restore
sort whatshot
keep if whatshot < 11
li packagename econ whatshot

sjlog close
