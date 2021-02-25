
** Code sample with fewer missing packages

** Contrived, shorter code snippet that contains fewer missing packages and less overall noise

// Packages: wyoung carryforward oaxaca


wyoung `v', cmd(regress OUTCOMEVAR hra_c_yr1, vce(robust)) familyp(hra_c_yr1) bootstrap(1000) seed (1234)	

bysort personid (negyear): carryforward educ2, gen(educ2b) back

reg personid treat, vce(robust)

oaxaca personid educ2 if hra_c_yr1==0

greshape gather f? p?, j(j) value(fp)

fegen personid = 0

drop sample_text
include "config.do"

*generate a variable equal to the contents of the do file
gen sample_text = "wyoung `v', cmd(regress OUTCOMEVAR hra_c_yr1, vce(robust)) familyp(hra_c_yr1) bootstrap(1000) seed (1234) bysort personid (negyear): carryforward educ2, gen(educ2b) back reg personid treat, vce(robust) oaxaca personid educ2 if hra_c_yr1==0 greshape gather f? p?, j(j) value(fp) fegen personid = 0"


* txttool cleaning
txttool sample_text, generate(cleaned_sample) stopwords("stopwords.txt") subwords("signalcommands.txt")