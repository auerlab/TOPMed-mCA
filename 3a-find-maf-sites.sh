#!/bin/sh -e

##########################################################################
#
#   Generate variant site lists for a given minimum allele frequency
#
#   This takes a couple days since it has to scan all the BCFs
#   Only needs to be run once and the results can be used for all
#   sample groups
#
#   This job should complete within several hours, since bcftools is
#   skipping most records (only processing those that meet the minimum
#   allele frequency).
#
#   All necessary tools are assumed to be in PATH.  If this is not
#   the case, add whatever code is needed here to gain access.
#   (Adding such code to your .bashrc or other startup script is
#   generally a bad idea since it's too complicated to support
#   every program with one environment.)
#
#   History:
#   Date        Name        Modification
#   2021-02-11  Jason Bacon Begin
##########################################################################

usage()
{
    printf "Usage: $0 MAF\n"
    exit 1
}


##########################################################################
#   Main
##########################################################################

if [ $# != 1 ]; then
    usage
fi
maf=$1
sbatch 3a-find-maf-sites.sbatch $maf
