#!/bin/sh -e

##########################################################################
#   Script description:
#       
#   Arguments:
#       
#   Returns:
#       
#   History:
#   Date        Name        Modification
#   2022-01-18  Jason Wayne BaconBegin
##########################################################################

usage()
{
    printf "Usage: $0 snpid nwdid\n"
    exit 1
}


##########################################################################
#   Main
##########################################################################

if [ $# != 2 ]; then
    usage
fi
snpid=$1
nwdid=$2

#awk -v snpid=$snpid '$3 == snpid { print $0 }' 67cbf3a8-output.filtered.001
chr=$(awk -v snpid=$snpid '$3 == snpid { print $1 }' 67cbf3a8-output.filtered.001)

svdir=../Data/79852-germline-structural-variants
bcftools view $svdir/sv.freeze1.$chr.gt.only.bcf \
    | mawk -v snpid=$snpid -v nwdid=$nwdid -f snpid-check.awk

