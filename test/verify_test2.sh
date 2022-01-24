#!/bin/bash


if [[ -f test2.log ]]
then
   # Verify first test: one of the files has a variable that is too long (var is 32char, but prepend makes it too long)
   grep -A 8 file_2=data/test2/longwords_nounderscores.do test2.log > actual_output2-1.txt
   diff actual_output2-1.txt test/expected_output2-1.txt || (echo "Not the expected output: Test 2-1"; exit 2)
   # Verify second test: cleanly processed the file with underscores. Should only find the expected output
   tail -8 test2.log | cut -b -17 > actual_output2-2.txt
   diff actual_output2-2.txt test/expected_output2-2.txt || (echo "Not the expected output: Test 2-2"; exit 2)
else
   echo "Something went wrong with running Stata"
   exit 2
fi

