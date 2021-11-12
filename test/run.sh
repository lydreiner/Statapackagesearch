#!/bin/bash

# Assumes stata-mp is in the path
# This does not work on Github Actions

stata-mp -b test/run.do
if [[ -f verify_test.sh ]]
then
   ./verify_test.sh
else
   test/verify_test.sh
fi
