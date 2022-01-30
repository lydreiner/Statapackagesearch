program p_whatshot
*! version 1.0.15  23jan2022
    version 14
    syntax , vars(string) [  debug ]

        local p_vars_hot `vars'
    	// Collect top hits at SSC for the past month 
    	tempfile whatshot

    	log using "`whatshot'", name(whatshot) replace text
    	* if the # of available packages ever exceeds 10000, adjust the line below
    	n ssc whatshot, n(10000)
    	log close whatshot

		// Data cleaning (import log file, export cleaned .dta file)

		*May need to adjust the starting value for rowrange- target the first line where the first package is mentioned

    	import delimited whitespace rank hits packagename authors using "`whatshot'", rowrange(8:) delimiters("       ", collapse) clear

    	gen byte notnumeric = real(hits)==.
		replace notnumeric = 1 if real(rank)==.
    	drop if notnumeric==1
    	drop authors-notnumeric
    	drop whitespace

		// clean up 
    	destring rank, replace
    	destring hits, replace
		keep packagename `p_vars_hot'
end
