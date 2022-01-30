{smcl}
{cmd:help packagesearch}{right: ({browse "http://www.stata-journal.com/":SJX-X: dmXXXX})}
{hline}

{title:Title}

{phang}{bf:packagesearch} {hline 2} Module to search Stata code for the SSC packages used by the code {p_end}

{title:Description}

{pstd}{cmd:packagesearch} provides a tool that scans, parses, and matches all Stata .do files in a directory (and its subdirectories) against a list of all packages currently hosted at SSC. It outputs a list of candidate SSC packages that were (likely) used when code is run.  

{title:Syntax}

{p 8 16 2}
{cmd:packagesearch} {cmd:,} 
{cmd:codedir({it:directorytoscan})}[
{cmd:domain({it:domain})}
{cmdab:files:ave}
{cmdab:excel:save}
{cmdab:nodrop:falsepos}
{cmdab:install:founds}]


{title:Options}

{phang}{opt codedir(directorytoscan)} is required. It specifies the directory that contains the .do files to be scanned for SSC packages.

{phang}{opt domain(domain)} optionally specifies a domain from which to take statistics to help identify likely packages (by default, {it:ssc hot} is used). Only available domain right now is {it:econ}.

{phang}{opt filesave} outputs a list of all files that were parsed during the scanning process.

{phang}{opt excelsave} saves the results of the scan into an Excel spreadsheet titled candidatepackages.xlsx. This file is saved in the specified {it:directorytoscan} and will include a list of parsed programs if {opt filesave} is also indicated as an option.

{phang}{opt nodropfalsepos} By default, command removes packages that were frequently found to be false positives during beta testing. This flag disables that feature. Presently this includes the following packages: {it: white, missing, index, dash, title, cluster, pre, bys}

{phang}{opt installfounds} installs all SSC packages found during the scanning process into the current working directory.


{title:Remarks}



{title:Examples}

{phang}{cmd:. packagesearch, codedir("C:/Users/username/myproject")}

{phang}{cmd:. packagesearch, codedir("C:/Users/username/myproject") filesave}

{phang}{cmd:. packagesearch, codedir("/home/username/myproject") excelsave nodropfalsepos installfounds}


{title:Authors}


{phang}Lars Vilhuber, Cornell University{p_end}
{phang}{browse "mailto:lars.vilhuber@cornell.edu":lars.vilhuber@cornell.edu}{p_end}


{phang}Lydia Reiner, independent researcher{p_end}
{phang}{browse "mailto:lr397@cornell.edu":lr397@cornell.edu}{p_end}


{title:Also see}

{p 4 14 2}
Article:  {it:Stata Journal}, volume XX, number XX: {browse "http://www.stata-journal.com/article.html?article=dm00XX":dm00XX}
