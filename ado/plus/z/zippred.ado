*! version 1.0.0 Jesper Sorensen 072998
program define zippred
    version 5.0
    if "$S_E_cmd"~="zip" & "$S_E_cmd"~="zinb"  { error 301 }
    else {
        local varlist "req new"
        local options "XB PRob"
        parse "`*'"
        parse "`varlist'", parse(" ")
	if "`xb'"=="" & "`prob'"=="" { local xb "xb" }
	if "`xb'"~="" { 
	     capture assert "`2'"==""
	     if _rc~=0 { error 103 }
	}
        /* generate predicted counts */
        tempname b poisb logitb lnalpha
        tempvar fishind logiti alpha
        matrix `b'=get(_b)
        if "$S_E_cmd"=="zip" {
            matrix `poisb'=`b'[.,"poisson:"]
        }
        else {
            matrix `poisb'=`b'[.,"nb:"]
            matrix `lnalpha'=`b'[.,"lnalpha:"]
        }
        matrix `logitb'=`b'[.,"logit:"]
        matrix score `fishind'=`poisb'
        matrix score `logiti'=`logitb'
        qui replace `fishind'=exp(`fishind')
        qui replace `logiti'=exp(`logiti')/(1+exp(`logiti'))
        /* subsitute predicted values, if requested (default) */
        if "`xb'"=="xb" {
            qui replace `1'=`fishind'-`fishind'*`logiti'
        }
        /* else compute probability of different counts */
        else if "`prob'"=="prob" {
            if "$S_E_cmd"=="zip" {            
       	        local i 1
		while "``i''"~="" {
                    local j=`i'-1
                    /* prob of zero count */
                    if `i'==1 {
                        qui replace ``i''=`logiti'+(1-`logiti')*exp(-`fishind')
                        label var ``i'' "Pr($S_E_depv=`j')"
                    }
                    /* prob of non-zero counts */
                    else {
                        qui replace ``i''=(1-`logiti')*(exp(-`fishind')*`fishind'^`j')/exp(lnfact(`j'))
                        label var ``i'' "Pr($S_E_depv=`j')"
                    } 
	            local i = `i'+1
                }
            }
            else {
                matrix score `alpha'=`lnalpha'
                qui replace `alpha'=1/exp(`alpha')
       	        local i 1
		while "``i''"~="" {
                    local j=`i'-1
                    /* prob of zero count */
                    if `i'==1 {
                        qui replace ``i''=`logiti'+(1-`logiti')*((`alpha'/(`alpha'+`fishind'))^`alpha')
                        label var ``i'' "Pr($S_E_depv=`j')"
                    }
                    /* prob of non-zero counts */
                    else {
                        qui replace ``i''=(1-`logiti')*( (exp(lngamma(`j'+`alpha')))/(exp(lnfact(`j'))*exp(lngamma(`alpha'))))
                        qui replace ``i''=``i''*((`alpha'/(`alpha'+`fishind'))^`alpha')
                        qui replace ``i''=``i''*((`fishind'/(`alpha'+`fishind'))^`j')
                        label var ``i'' "Pr($S_E_depv=`j')"
                    } 
	            local i = `i'+1
                }
            }
        }
    }
end

