[![Test CI Stata](https://github.com/AEADataEditor/Statapackagesearch/actions/workflows/test.yml/badge.svg)](https://github.com/AEADataEditor/Statapackagesearch/actions/workflows/test.yml)
[![Run](https://github.com/AEADataEditor/Statapackagesearch/actions/workflows/test.yml/badge.svg?event=workflow_run)](https://github.com/AEADataEditor/Statapackagesearch/actions/workflows/test.yml)


# `Packagesearch`: module to scan Stata .do files and identify SSC packages used by the code

## Installation
To install, type the following command into Stata. 

```
net install packagesearch, from("https://aeadataeditor.github.io/Statapackagesearch/")
```

## Syntax: (also available in the help file)

`packagesearch, codedir(directorytoscan)[ filesave excelsave econstats falsepos installfounds]`

`codedir(directorytoscan)` is required. It specifies the directory that contains the .do files to be scanned for SSC packages.

`filesave` outputs a list of all files that were parsed during the scanning process.

`excelsave` saves the results of the scan into an Excel spreadsheet titled candidatepackages.xlsx. 
- This file is saved in the specified directorytoscan and will include a list of parsed programs if filesave is also indicated as an option.

`econstats` matches the scanned .do files against a list of packages commonly found in replication packages for AEA economics research articles (rather than a list of all packages in existence at SSC)
- This option will improve the accuracy (reduce # of false positives) when scanning Stata code that is used in economics research

`falsepos` removes packages that were frequently found to be false positives during beta testing. 
- Presently this includes the following packages: `white, missing, index, dash, title, cluster, pre, bys`. 
- This option becomes slightly redundant with the `econstats` option, so one or the other is recommended

`installfounds` installs all SSC packages found during the scanning process into the current working directory.




## Description:

The code begins by either collecting a list of all packages hosted at SSC using the `whatshot` command, or pulling a list of common SSC packages used in economics research (if option `econstats` is specified).   
Next, it identifies all .do files in the specified `codedir` directory and subdirectories, then parses each .do file into individual words using the `txttool` command. 
Finally, it matches the individual words against the list of SSC packages and outputs a list of candidate packages that were (likely) used when the Stata code was run.  

### Questions?
Contact:   
Lydia Reiner (lr397@cornell.edu)  
Lars Vilhuber (lars.vilhuber@cornell.edu)


