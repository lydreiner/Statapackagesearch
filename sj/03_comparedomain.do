/* compute some stats */

include "config.do"
sjlog using 03_comparedomain, replace

use "$pkgroot/p_stats_econ.dta"
rename rank econ
tempfile econ
save `econ'

net install packagesearch, from("$pkgroot") replace
p_whatshot, vars(rank hits)
rename rank whatshot

sort packagename
merge 1:1 packagename using `econ'
preserve
sort econ
keep if econ < 11
li packagename econ whatshot
/* print to table */
listtab packagename  econ whatshot using 03_table1.tex , rstyle(tabular) replace head("\begin{tabular}{lrr}\toprule" ///
            "Packagename&\texttt{econ}&\texttt{whatshot}\\\midrule") foot("\bottomrule\end{tabular}")


restore
sort whatshot
keep if whatshot < 11
li packagename econ whatshot
/* print to table */
listtab packagename  econ whatshot using 03_table2.tex , rstyle(tabular) replace  head("\begin{tabular}{lrr}\toprule" ///
            "Packagename&\texttt{econ}&\texttt{whatshot}\\\midrule") foot("\bottomrule\end{tabular}")

sjlog close, replace
