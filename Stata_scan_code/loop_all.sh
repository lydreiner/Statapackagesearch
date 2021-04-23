#!/bin/bash

if [[ -z $1 ]] 
then
cat << EOF
  $0 DIR [start end]

  will start a scan of all directories underneat DIR for Stata packages
  (optionally between start and end)
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
   skip=no
   # check there is a directory
   if [[ -d $scandir/$aearep ]] 
   then
      if [[ -f "$scandir/$aearep/candidatepackages.xlsx" ]]
      then
         skip=yes
         echo "Already run for $aearep - skipping"
      fi
   else
      echo "$scandir/$aearep not directory - skipping"
      skip=yes
   fi


   if [[ "$skip" == "no" ]]
   then
     outfile=run_$aearep.do
   
     cat > $outfile << EOF
// $(date)
global scandir "$scandir"
global aearep  "$aearep"
di "Timer on: \`c(current_date)' \`c(current_time)'"
include scan_packages.do
di "Timer off: \`c(current_date)' \`c(current_time)'"


EOF

else
   # nothing to do
      echo "Skipping $arg"
   fi
done

