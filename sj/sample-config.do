/* install any packages locally */
capture mkdir "$rootdir/ado"
sysdir set PERSONAL "$rootdir/ado/personal"
sysdir set PLUS     "$rootdir/ado/plus"
sysdir set SITE     "$rootdir/ado/site"
local ssc_packages "pkg1 pkg2"

if !missing("`ssc_packages'") {
	foreach pkg in `ssc_packages' {
		capture which `pkg'
		if _rc == 111 {                 
			dis "Installing `pkg'"
			ssc install `pkg', replace
		}
		which `pkg'
	}
}