* Preliminaries

*Set working directory here
global rootdir "U:/Documents/AEA_workspace/FunPackageSearch/Statapackagesearch-scan_aearep"

ssc install filelist


* Scan files in subdirectories
	tempfile file_list 
	filelist, directory("$rootdir/Data") pattern("candidatepackages.xlsx")
	gen temp="/"
	egen file_path = concat(dirname temp filename)
	save `file_list'
	keep file_path
	
qui count
	local total_files = `r(N)'
	forvalues i=1/`total_files' {
		local file_`i' = file_path[`i']
	}

* Read in excel file
forvalues i=1/`total_files' {
	n di "file_`i'=`file_`i''"
	global v = "`file_`i''"
	
	*create new dta file for first instance
	
	if `i' == 1 {
		*tempfile aggCP
		import excel using $v, clear
		save $rootdir/aggCP.dta, replace
	}
	
	* Append this .dta with each add'l excel file
	else {
		use $rootdir/aggCP.dta
	    import excel using $v, clear
		append using $rootdir/aggCP.dta
		save $rootdir/aggCP.dta, replace
	}
	
}
	

	*Data cleaning
	use "$rootdir/aggCP.dta", clear
	drop if A =="(Potential) missing package found"
	
	label var A "(Potential) missing package found"
	rename A candidatepkg
	label var B "Package popularity (rank out of total # of packages)"
	rename B pkgpopularity
	label var C "likelihood of false positive based on package popularity"
	rename C probfalsepos
	
	rename D confirm_is_used
	

	destring probfalsepos pkgpopularity confirm_is_used, replace
	
	*If column D is missing (cannot determine if package was used or not), replace with value of 2
	replace confirm_is_used = 2 if missing(confirm_is_used)

	cap log close
log using $rootdir/summarystats.txt, replace

	*Summary stats
	count if probfalsepos==0
	tab candidatepkg, sort
	tab confirm_is_used
	
	* Most common actual packages
	preserve
	
	drop if confirm_is_used ==2 
	drop if confirm_is_used ==0 
	di as input "Most common packages"
	tab candidatepkg, sort
	
	restore
	
	* Most common false positives
	preserve
	
	drop if confirm_is_used ==2 
	drop if confirm_is_used ==1 
	di as input "Most common false positives"
	tab candidatepkg, sort
	
	restore
	cap log close