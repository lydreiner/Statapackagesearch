// https://stackoverflow.com/questions/7924702/looking-for-a-sample-program-to-test-stata-mp

set more off
cap set processors 8
clear*
set rmsg on
global size 10000000
global dims 5
global reps 200

set obs     $size
forval n = 1/$dims {
g i`n' = runiform()
}
g dv = rbinomial(1,.3)
memory

// r; m=logit
qui logit dv i*
// r; m=xtmixed
qui xtmixed dv i*

*with bootstrap:
// r; m=bootstrap
qui bs, reps($reps): logit dv i*

exit, clear

