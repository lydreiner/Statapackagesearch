** Master file for text-mining based package search

** Preliminaries
clear all

// Set globals below

// Point to location of "final_framework" folder which contains scanning code, package list, and stopwords & subwords files
global rootdir "U:/Documents/AEA_Workspace/Statapackagesearch/final_framework/code"

// Point to location of folder with .do files to scan:
global codedir "U:/Documents/AEA_Workspace/aearep-1600"
cd "$codedir"

// Install packages, create log file, provide system info
include "$rootdir/config.do"

** Parse each .do file in a directory, then append the parsed files
do "$rootdir/parse.do"


** Matching code- match analyzed output to package list and show missing packages.
do "$rootdir/match.do"