#!/bin/sh -e

##########################################################################
#   Script description:
#       Select the Nth sample from a list where N is in $1
#       
#   History:
#   Date        Name        Modification
#   2021-12-02  Jason Wayne BaconBegin
##########################################################################

usage()
{
    printf "Usage: $0 N\n"
    exit 1
}


##########################################################################
#   Main
##########################################################################

if [ $# != 1 ]; then
    usage
fi
n=$1

cd Data/1c-combine

# Pick a sample from the list based on n
max_lines=$(cat sample-list-0000 | wc -l)
split_file_num=$(( ($n - 1) / $max_lines ))
split_file=$(printf "sample-list-%04d" $split_file_num)
line=$(( ($n - 1) % $max_lines + 1 ))
awk -v line=$line 'NR == line { print $1 }' $split_file
