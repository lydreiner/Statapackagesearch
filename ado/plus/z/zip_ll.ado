*! version 1.0.0 Jesper Sorensen 042298
program define zip_ll
    version 5.0
    local f `1'
    local xbeta `2'   /* poisson equation */
    local zgamma `3'  /* logit equation */
qui {
    tempvar rr a L1 L2 zg xb mu
    gen double `mu' = exp(`xbeta')
    gen double `zg' = exp(`zgamma')
#delimit ;
    gen double `L1' = (`zg'/(1+`zg'))+(1/(1+`zg'))*exp(-`mu') if $S_mldepn==0;
    replace `L1' = log(`L1');
    gen double `L2' = log(1/(1+`zg'))-`mu' + $S_mldepn*`xbeta'
        -lnfact($S_mldepn) if $S_mldepn>0;
        

#delimit cr
    replace `f' = cond($S_mldepn==0,`L1',`L2')
}
end
    
    
