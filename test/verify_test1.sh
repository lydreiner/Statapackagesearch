#!/bin/bash

if [[ -f test1.log ]]
then
   tail -8 test1.log > actual_output.txt
   diff actual_output.txt test/expected_output1.txt || (echo "Not the expected output"; exit 2)
else
   echo "Something went wrong with running Stata"
   exit 2
fi

