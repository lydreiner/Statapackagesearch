#!/bin/bash

# Assumes stata-mp is in the path

stata-mp -b test/install-tmp.do
stata-mp -b test/test1.do
if [[ -f verify_test1.sh ]]
then
   ./verify_test1.sh
else
   test/verify_test1.sh
fi


# Testing for what happens when there are long wors

stata-mp -b test/test2.do
if [[ -f verify_test2.sh ]]
then
   ./verify_test2.sh
else
   test/verify_test2.sh
fi
