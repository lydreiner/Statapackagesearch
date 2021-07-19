clear all

* Preliminaries

local pwd : pwd
global rootdir "`pwd'"

capture mkdir "$rootdir/ado"
sysdir set PERSONAL "$rootdir/ado/personal"
sysdir set PLUS     "$rootdir/ado/plus"
sysdir set SITE     "$rootdir/ado/site"
sysdir

/* add packages to the macro */

* *** Add required packages from SSC to this list ***
    local ssc_packages "strip"
    // local ssc_packages "estout boottest"
    
    if !missing("`ssc_packages'") {
        foreach pkg in `ssc_packages' {
            dis "Installing `pkg'"
            ssc install `pkg', replace
        }
    }

* Data Cleaning master csv file	
	
import delimited "\\rschfs1x\userRS\K-Q\lr397_RS\Documents\AEA_workspace\FunPackageSearch\Statapackagesearch\Data\count_all.csv", clear

drop v4-nextup370
drop if key != "adofile"

replace value = substr(value,1,strlen(value)-4)
strip value, of("_") generate(cleaned_value)

replace value = cleaned_value
drop cleaned_value
rename value candidatepkg


* Cleaning individual xlsx files

strip aearep, of("aearep-") generate(folderNumbers)
destring folderNumbers, replace

levelsof folderNumbers, local(levels)

save $rootdir/matchado.dta, replace

* Add column with folder name to each candidatepackages.xlsx files and save as dta

*can be commented out once run successfully
/*
foreach 1 of local levels {
	cap import excel \\rschfs1x\userRS\K-Q\lr397_RS\Documents\AEA_workspace\FunPackageSearch\Statapackagesearch\Data\aearep-`1'\candidatepackages.xlsx, clear
	if _rc ==0 {
	
	drop if A =="(Potential) missing package found"
	
	label var A "(Potential) missing package found"
	rename A candidatepkg
	label var B "Package popularity (rank out of total # of packages)"
	rename B pkgpopularity
	label var C "likelihood of false positive based on package popularity"
	rename C probfalsepos
	
	rename D confirm_is_used

	gen foldername = "aearep-`1'"
	save $rootdir/Data/aearep-`1'/candidatepackages_aearep-`1'.dta, replace
	}

	}
*/

* cross refer

tempfile matchresults


foreach v of local levels {
	
	n di "currently running `v'"
	
	capture confirm file $rootdir/Data/aearep-`v'/candidatepackages_aearep-`v'.dta
if !_rc {
	* do something if the file exists

	
	use "$rootdir/matchado.dta"
	drop if folderNumbers != `v'
	drop aearep key
	
	* rm duplicates
	sort candidatepkg
	by candidatepkg:  gen dup = cond(_N==1,0,_n)
	drop if dup>1
	
	tempfile subset
	save `subset'
	
	
	sort candidatepkg
		merge 1:1 candidatepkg using $rootdir/Data/aearep-`v'/candidatepackages_aearep-`v'.dta
	
	keep if _merge==3
	keep candidatepkg
	
	cap append using `matchresults'
	save `matchresults', replace
	
	/*
	cap sort candidatepkg
	if _rc ==0 {
	merge 1:1 candidatepkg using $rootdir/Data/aearep-`1'/candidatepackages_aearep-`1'.dta
	
	list if _merge==3
	*/
	}
	
	else {
		di "no candidatepackages.xlsx generated for this issue"
	}
	
	}
	
	use `matchresults', clear
	save "$rootdir/matchresults.dta", replace
	
	*Cleaning- collapse into unique packages and count of observations
	use "$rootdir/matchresults.dta", clear
	gen uniquepkgs = candidatepkg
	sort uniquepkgs
	qui by uniquepkgs : gen dup = cond(_N==1,0,_n)
	replace uniquepkgs="." if dup>1
	
	egen frequency = count(uniquepkgs), by(candidatepkg)
	drop if dup>1
	drop dup uniquepkgs
	
	gsort -frequency
rename candidatepkg packagename
rename frequency hits
gen rank = _n
order rank hits packagename

	
	save "$rootdir/matchresults.dta", replace

	
	
	* whatshot vs results for packagesearch.ado file- allow toggle (required option?)- way to switch between
	* then run basic tests- should have stronger suggestion of true packages with less false positives
	
	* name it something that indicates it;s from econ (want to be able to add other disciplines)
	*final file will have package, frequency, field ("econ")
	* may miss things (b/c not using whatshot) - that's OK
		*long term goal- blend of the two (weighted average)
		
		*have matchresults as an ancillary file that gets pulled from github

