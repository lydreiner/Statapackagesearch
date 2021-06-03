# `Packagesearch`: module to scan Stata .do files and identify SSC packages used by the code

## Installation
To install, type the following command into Stata. 

Note: There are two required ancillary files (`signalcommands.txt` and `stopwords.txt`) that are automatically pulled from the repository after the first use of the `packagesearch` command.

```
net install packagesearch, from("https://lydreiner.github.io/Statapackagesearch/")
```


## Syntax: (also available in the help file)

`packagesearch, codedir(directorytoscan)[ filesave excelsave falsepos installfounds]`

`codedir(directorytoscan)` is required. It specifies the directory that contains the .do files to be scanned for SSC packages.

`filesave` outputs a list of all files that were parsed during the scanning process.

`excelsave` saves the results of the scan into an Excel spreadsheet titled candidatepackages.xlsx. 
- This file is saved in the specified directorytoscan and will include a list of parsed programs if filesave is also indicated as an option.

`falsepos` removes packages that were frequently found to be false positives during beta testing. 
- Presently this includes the following packages: `white, missing, index, dash, title, cluster, pre, bys`. 

`installfounds` installs all SSC packages found during the scanning process into the current working directory.


## Description:

The code begins by collecting a list of all packages hosted at SSC using the `whatshot` command, Next, it identifies all .do files in the specified `codedir` directory and subdirectories, then parses each .do file into individual words using the `txttool` command. 
Finally, it matches the individual words against the list of SSC packages and outputs a list of candidate packages that were (likely) used when the Stata code was run.  

### Questions?
Contact:   
Lydia Reiner (lr397@cornell.edu)  
Lars Vilhuber (lars.vilhuber@cornell.edu)


