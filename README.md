# R_code branch

Repository contains 2 scripts (.R and .do) that perform the same function as the `packagesearch` command.

Stata: 

- scan_packages.do : Performs scan for missing packages. Please set globals as noted in the "Step 1 Preliminaries" section in the code.
  - subfolder `ado/auxiliary` contains necessary stopwords and subwords files as used in the program. Also includes ado files for all necessary packages used in the scanning process.

R Code:

- stata_package_search.R: R code that scans all .do files in a specified folder for missing packages and outputs them in a list. Includes missing packages obtain from the finding the package itself in the code as well as signal commands and dependencies.  

- Package_list.xlsx: list of (nearly) all user-contributed Stata packages obtained via the "minessc" command in Stata.
  - document has 3 columns: 
      - A: Package: name of the package 
      - B: Signals: any signal commands that indicate use of that package (e.g command `gisin` signals the use of package `gtools`)
      - C: Dependencies (e.g- `ftools` is a required dependency of `reghdfe`)
  - list is incomplete- Signals and Dependencies are manually created and thus not exhaustive

Misc:

- `fewmissing packages.do` and `lotsofmissingpackages.do`: sample .do files for testing the code. Include the list of missing packages as a comment in the top of both programs so users can verify results.  



