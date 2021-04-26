#!/bin/bash

echo "aearep,key,value" > count_all.csv
for arg in count_aearep-*csv
do 
  tail -n +2 $arg >> count_all.csv 
done

