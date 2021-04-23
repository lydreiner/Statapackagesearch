#!/bin/bash

if [[ -z $1 ]] 
then
cat << EOF
  $0 DIR [start end]

  will start a scan of all directories underneat DIR for Stata packages
  (optionally between start and end)
  and count the number of do files.

  also, when a "ado" directory is found, all files in there are listed.
EOF
exit 2
fi

if [[ -d $1 ]]
then
  scandir=$1
  echo "Scanning $scandir ..."
  dirs=$(ls -1d $scandir/aearep* | wc -l)
  echo "  Found: $dirs directories"
  echo "Do you want to proceed?"
  read
else
  echo "$1 not a directory"
  exit 2
fi
shift
start=$1
[[ -z $start ]] && start=1
shift
stop=$1
[[ -z $stop ]] && stop=3000

for arg in $(seq $start $stop)
do

   aearep=aearep-$arg
   skip=yes
   # check there is a directory
   #if [[ -f "$scandir/$aearep/candidatepackages.xlsx" ]]
   if [[ -d "$scandir/$aearep" ]]
   then
      skip=no
   fi

   if [[ "$skip" == "no" ]]
   then
     outfile=count_$aearep.csv
     echo "aearep,key,value" > $outfile 
     echo "$aearep,docount,$(find $scandir/$aearep -type f -name \*.do | wc -l)"  >> $outfile
     echo "$aearep,adocount,$(find $scandir/$aearep -type f -name \*.ado | wc -l)"  >> $outfile
     # check for ado dirs
     adodirs=$(find $scandir/$aearep -type d -name ado)
     if [[ $(echo "$adodirs" | wc -l) -gt 0 ]]
     then
        find $scandir/$aearep -type d -name ado | \
             xargs -d '\n' -I % find % -type f -name \*.ado -exec basename {} \; |\
             awk -v aearep=$aearep ' { print aearep ",adofile," $0 } ' >> $outfile
     fi
   else
   # nothing to do
      echo "Skipping $arg"
   fi
done

exit
