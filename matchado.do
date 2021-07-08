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

save matchado.dta, replace

* Add column with folder name to each candidatepackages.xlsx files

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

foreach 1 of local levels {
	preserve
	use $rootdir/matchado.dta
	drop if folderNumbers != `1'
	drop aearep key 
	
	cap sort candidatepkg
	if _rc ==0 {
	merge 1:1 candidatepkg using $rootdir/Data/aearep-`1'/candidatepackages_aearep-`1'.dta
	
	list if _merge==3
	}
	restore
	
}

