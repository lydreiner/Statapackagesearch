* main.do
* This script is the main driver for this directory.  It should run all the do
* files that generate output, and possibly generate some output of its own.

include "config.do"

do 01_whatshot.do
sjlog type 01_whatshot.do, replace

* finished main.do
