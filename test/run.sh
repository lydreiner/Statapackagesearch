#!/bin/bash

# Assumes stata-mp is in the path
# This does not work on Github Actions

stata-mp -b test/test1.do
if [[ -f verify_test.sh ]]
then
   ./verify_test1.sh
else
   test/verify_test1.sh
fi
