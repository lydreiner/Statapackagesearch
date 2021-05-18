*! Command line version of tabmenu1
*! Michael Hills 1/5/2002
*! version 3.0.0

program define tabmenu2
version 7.0
syntax [varlist] [if] [in] , RES(string) TYP(string) ROW(string) /* 
*/ [Col(string) SUMMary(string) FUP(string) PERC(integer 100) /* 
*/ PERY(integer 1000) MAXval(integer 10) FR CI RV LEVel(integer $S_level)]

di
macro drop TA_*
macro drop ta_*

global ta_res `res'
global ta_typ `typ'
global ta_fup `fup'
global ta_exp `row'
global ta_mod `col'
if "`typ'"=="metric" {
    if "`summary'"=="mean" {global ta_sca 1}
    if "`summary'"=="gmean" {global ta_sca 2}
    if "`summary'"=="median" {global ta_sca 3}
}
if "`typ'"=="binary" {
    if "`summary'"=="prop" {global ta_sca 1}
    if "`summary'"=="odds" {global ta_sca 2}
}
if "`typ'"=="failure" | "`type'"=="count" {
    global ta_sca 1
}
global ta_perc `perc'
global ta_pery `pery'
global ta_mv `maxval'
global ta_fr 1
if "`fr'" == "" {global ta_fr 0}
global ta_ci 1
if "`ci'" == "" {global ta_ci 0}
global ta_rv 1
if "`rv'" == "" {global ta_rv 0}
global ta_lev `level'

/* basic error checking 1*/

global ta_exp = ltrim("$ta_exp")
global ta_mod = ltrim("$ta_mod")
global ta_res = ltrim("$ta_res")

if "$ta_res"=="" {
    di as error "No response variable has been specified!"
    exit
}
else {
    cap confirm numeric variable $ta_res
    if _rc==7 {
        di as error "Response variable must be numeric"
        exit
  }
}
if "$ta_typ" == "" {
    di as error "Type of response variable must be selected"
    exit
}
if "$ta_exp"=="" {
    di as error "Explanatory variable must be specified"
    exit
}
if "$ta_res"=="$ta_exp" | "$ta_res"=="$ta_mod" {
    di as error "Variable occurs as both response and explanatory"
    exit
}
if "$ta_mod"=="$ta_exp" {
    di as error "Same variable occurs as both row and column"
    exit
}
qui inspect $ta_exp
if r(N_unique)>$ta_mv {
    di as error "More than $ta_mv values for row variable"
    exit
} 
if "$ta_mod" != "" {
    qui inspect $ta_mod
    if r(N_unique)>$ta_mv {
        di as error "More than $ta_mv values for column variable"
        exit
    } 
}
if "$ta_typ"=="failure" {
    cap assert $ta_res ==0 | $ta_res ==1 | $ta_res==.
    if _rc==9 {
        di as error "Failure response must be coded 0/1"
        exit
    }
}
if "$ta_typ"=="binary" {
    cap assert $ta_res ==0 | $ta_res ==1 | $ta_res==.
    if _rc==9 {
        di as error "Binary response must be coded 0/1"
        exit
    }
    cap assert "$ta_fup" == "" 
    if _rc==9 {
        di as error "Cannot have follow-up time with binary response"
        exit
    } 
}
if "$ta_typ"=="failure" | "$ta_typ"=="count"  {
    cap assert "$ta_fup" != ""
    if _rc==9 {
        di as error "Failure and count responses must have follow-up time"
        exit
    }
}
_mhtab `if' `in' , level($ta_lev)
end

program define _mhtab
version 7.0
syntax [if] [in] [,Level(integer $S_level)]
tempvar se hi low ci to odds rate iqr contents touse
marksample touse
markout `touse' $ta_res $ta_exp $ta_mod $ta_fup

preserve

di in gr "Response variable is: " in ye "$ta_res" in gr " which is "in ye "$ta_typ"
if "$ta_fup" != "" {
    di in gr "Follow-up time variable is: " in ye "$ta_fup"
}
di in gr "Row variable is: " in ye "$ta_exp "
if "$ta_mod"!="" {
    di in gr "Column variable is: " in ye "$ta_mod " 
}

/* Prints number of records used */

qui count if `touse'
di as text "Number of records used:    " as result r(N)        
if $ta_ci==1 {
    di as res `level' "%" as text " confidence intervals"
}


local mult = invnorm(`level'*0.005+0.5)

* binary

if "$ta_typ"=="binary" {

* proportions

    if    $ta_sca==1 {
        di in gr _n(1) "Summary using" in ye " proportions"    in gr " per " in ye $ta_perc
        qui table $ta_exp $ta_mod if `touse', c(freq mean $ta_res) replace
        qui gen `odds'=table2/(1-table2)
        qui gen `se' = sqrt(1/(table1*table2)+1/(table1*(1-table2)))
        qui gen `low' = `odds'/exp(`mult'* `se')
        qui gen `hi'    = `odds'*exp(`mult'* `se')
        qui replace `low' = $ta_perc*`low'/(1+`low')
        qui replace `hi'    = $ta_perc*`hi'/(1+`hi')
        qui replace table2=$ta_perc*table2
        qui gen str1 `to' = "-"
        egen `ci' = concat(`low' `to' `hi'), punct(" ") format(%7.2f)
        local contents "table2"
        if $ta_fr==1 { local contents "table1 `contents'"}
        if $ta_ci==1 { local contents "`contents' `ci'" }
        label var table2 $ta_res
        label var `ci' "$ta_lev% CI"
        if $ta_rv==1 {tabdisp $ta_mod $ta_exp, cell(`contents') format(%7.2f) cellwidth(20)}
        else { tabdisp $ta_exp $ta_mod, cell(`contents') format(%7.2f) cellwidth(20)}
    }

* odds

    if $ta_sca==2 {
        di in gr    _n(1) "Summary using" in ye " odds"
        qui table $ta_exp $ta_mod if `touse', c(freq mean $ta_res) replace
        qui gen `odds'=table2/(1-table2)
        qui gen `se' = sqrt(1/(table1*table2)+1/(table1*(1-table2)))
        qui gen `low' = `odds'/exp(`mult'* `se')
        qui gen `hi'    = `odds'*exp(`mult'* `se')
        qui replace table2=`odds'
        qui gen str1 `to' = "-"
        egen `ci' = concat(`low' `to' `hi'),    punct(" ") format(%7.4f)
        local contents " table2 "
        if $ta_fr==1 { local contents "table1 `contents'"}
        if $ta_ci==1 { local contents "`contents' `ci'" }
        label var table2 $ta_res
        label var `ci' "$ta_lev% CI"
        if $ta_rv==1 {tabdisp $ta_mod $ta_exp, cell(`contents') format(%7.4f) cellwidth(20)}
        else { tabdisp $ta_exp $ta_mod, cell(`contents') format(%7.4f) cellwidth(20)}
    }
}

* failure or count

if "$ta_typ"=="failure" | "$ta_typ"=="count" {
        di in gr    _n(1) "Summary using" in ye " rates" in gr " per " in ye    $ta_pery
        qui table $ta_exp $ta_mod if `touse', c(freq sum $ta_res sum $ta_fup) replace
        qui gen `rate' = table2/table3*$ta_pery
        qui gen `se' = sqrt(1/table2)
        qui gen `low' = `rate'/exp(`mult'* `se')
        qui gen `hi'    = `rate'*exp(`mult'* `se')
        qui replace table2 = `rate'
        qui gen str1 `to' = "-"
        egen `ci' = concat(`low' `to' `hi'), punct(" ") format(%7.2f)
        local contents " table2 "
        if $ta_fr==1 { local contents "table1 `contents'"}
        if $ta_ci==1 { local contents "`contents' `ci'" }
        label var table2 $ta_res
        label var `ci' "$ta_lev% CI"
        if $ta_rv==1 {tabdisp $ta_mod $ta_exp, cell(`contents') format(%7.2f) cellwidth(20)}
        else { tabdisp $ta_exp $ta_mod, cell(`contents') format(%7.2f) cellwidth(20)}
}

if "$ta_typ"=="metric" {
    if $ta_sca==1 {
        di in gr    _n(1) "Summary using" in ye " means"
        qui table $ta_exp $ta_mod    if `touse', c(freq mean $ta_res sd $ta_res) replace
        qui gen `se' = table3/sqrt(table1)
        qui gen `low' = table2 - `mult'*`se'
        qui gen `hi' = table2 + `mult'*`se'
        qui gen str1 `to' = "-"
        egen `ci' = concat(`low' `to' `hi'), punct(" ") format(%7.2f)
        local contents " table2 "
        if $ta_fr==1 { local contents "table1 `contents'"}
        if $ta_ci==1 { local contents "`contents' `ci'" }
        label var table2 $ta_res
        label var `ci' "$ta_lev% CI"
        if $ta_rv==1 {tabdisp $ta_mod $ta_exp, cell(`contents') format(%7.2f) cellwidth(20)}
        else { tabdisp $ta_exp $ta_mod, cell(`contents') format(%7.2f) cellwidth(20)}
    }
    if $ta_sca==2 {
        di in gr    _n(1) "Summary using" in ye " geometric means"
        qui assert $ta_res > 0
        qui replace $ta_res=ln($ta_res)
        qui table $ta_exp $ta_mod if `touse', c(freq mean $ta_res sd $ta_res) replace
        qui gen `se' = table3/sqrt(table1)
        qui gen `low' = table2 - `mult'*`se'
        qui gen `hi' = table2 + `mult'*`se'
        qui replace table2=exp(table2)
        qui replace `low'=exp(`low')
        qui replace `hi'=exp(`hi')
        qui gen str1 `to' = "-"
        egen `ci' = concat(`low' `to' `hi'), punct(" ") format(%7.2f)
        local contents " table2 "
        if $ta_fr==1 { local contents "table1 `contents'"}
        if $ta_ci==1 { local contents "`contents' `ci'" }
        label var table2 $ta_res
        label var `ci' "$ta_lev% CI"
        if $ta_rv==1 {tabdisp $ta_mod $ta_exp, cell(`contents') format(%7.2f) cellwidth(20)}
        else { tabdisp $ta_exp $ta_mod, cell(`contents') format(%7.2f) cellwidth(20)}
    }
    if $ta_sca==3 {
        di in gr    _n(1) "Summary using" in ye " medians"
        qui table $ta_exp $ta_mod if `touse', c(freq med $ta_res p25 $ta_res p75 $ta_res) replace
        qui gen `low' = table3
        qui gen `hi' = table4
        gen str1 `to' = "-"
        egen `iqr' = concat(`low' `to' `hi'), punct(" ") format(%7.2f)
        local contents " table2 "
        if $ta_fr==1 { local contents "table1 `contents'"}
        if $ta_ci==1 { local contents "`contents' `iqr'" }
        label var table2 $ta_res
        label var `iqr' "IQR "
        if $ta_rv==1 {tabdisp $ta_mod $ta_exp, cell(`contents') format(%7.2f) cellwidth(20)}
        else { tabdisp $ta_exp $ta_mod, cell(`contents') format(%7.2f) cellwidth(20)}
    }
}

end
