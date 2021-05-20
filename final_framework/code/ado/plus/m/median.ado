program define median
        version 5.0
        local varlist "req ex max(1)"
        local options "BY(string) cc"
        local if "opt"
        local in "opt"
        parse "`*'"
        local x "`varlist'"
        if "`by'" == "" {
                di in red "by() option required"
                exit 100
        }
        unabbrev `by', max(1)
        local by "$S_1"
        tempname g1 g2 hilab
        tempvar touse median hi
        mark `touse' `if' `in'
        markout `touse' `x' `by'
        quietly {
                summarize `by' if `touse',detail
                if _result(1) == 0 { noisily error 2000 }
                if _result(5) == _result(6) {
                        di in red "1 group found, 2 required"
                        exit 499
                }
                scalar `g1' = _result(5)
                scalar `g2' = _result(6)

                count if `by'!=`g1' & `by'!=`g2' & `touse'
                if _result(1) != 0 {
                        di in red "more than 2 groups found, only 2 allowed"
                        exit 499
                }

                egen double `median' = median(`x') if `touse'

                gen double `hi' = 0 if `touse'
                replace `hi' = 1 if `x'>=`median' & `touse'
                label var `hi' "Above the median"
                label def `hilab'  0 "No" 1 "yes"
                label values `hi' `hilab'
        }

        if "`cc'" =="" {
                di in gr _n "Median test (without continuity correction)" _n
                tab `hi' `by' if `touse' , chi exact
        }
        else {
                di in gr _n "Median test (with continuity correction)" _n
                tab `hi' `by' if `touse'
                qui count if `hi'==0 & `by'==`g1' & `touse'
                local A =_result(1)
                qui count if `hi'==0 & `by'==`g2' & `touse'
                local B =_result(1)
                qui count if `hi'==1 & `by'==`g1' & `touse'
                local C =_result(1)
                qui count if `hi'==1 & `by'==`g2' & `touse'
                local D =_result(1)
                tempname chi2 N
                scalar `N'= `A'+`B'+`C'+`D'
                scalar `chi2'=`N'* (abs(`A'*`D' - `B'*`C')-(`N'/2))^2
                scalar `chi2'=`chi2'/((`A'+`B')*(`C'+`D')*(`A'+`C')*(`B'+`D'))
                noi di in gr "          chi2(" in ye "1" in gr ") = " /*
                */ in ye %10.4f `chi2' /*
                */ in gr "    Pr = " in ye %6.4f chiprob(1,`chi2')
        }
end