program testado
version 16.1
    *syntax dirtoscan , [ FILESave EXCELsave(string) FALSEPos INSTALLfounds]

***************************
* Step 1: Preliminaries   *
***************************

qui {
clear all
local pwd : pwd

global rootdir "`pwd'"

capture mkdir "$rootdir/ado"
sysdir set PERSONAL "$rootdir/ado/personal"
sysdir set PLUS     "$rootdir/ado/plus"
sysdir set SITE     "$rootdir/ado/site"
sysdir

/* add necessary packages to perform the scan & analysis to the macro */

* *** Add required packages from SSC to this list ***
    local ssc_packages "fs filelist txttool"
    
    if !missing("`ssc_packages'") {
        foreach pkg in `ssc_packages' {
            n dis "Installing `pkg'"
            ssc install `pkg', replace
        }
    }

/* after installing all packages, it may be necessary to issue the mata mlib index command */
	mata: mata mlib index


set more off
set maxvar 120000
}
di "required packages installed"


end