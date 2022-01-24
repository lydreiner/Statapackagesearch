#!/bin/bash

if [[ -f test1.log ]]
then
   tail -8 test1.log | cut -b -17 > actual_output.txt
   diff actual_output.txt test/expected_output1.txt || (echo "Not the expected output: Test 1-1"; exit 2)
else
   echo "Something went wrong with running Stata"
   exit 2
fi

