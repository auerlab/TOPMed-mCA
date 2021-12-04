#!/bin/sh -e

##########################################################################
#
#   Find sites with MAF > 1%
#
#   Do not submit this script directly.  Use 1b-compress.sh.
#       
#   History:
#   Date        Name        Modification
#   2020-08-14  Jason Bacon Begin
##########################################################################

#SBATCH --array=1-23
#SBATCH --mem=200
#SBATCH --output=Logs/3-filter/find-maf-sites-%A_%a.out
#SBATCH --error=Logs/3-filter/find-maf-sites-%A_%a.err

usage()
{
    printf "Usage: $0 MAF\n"
    exit 1
}

if [ $# != 1 ]; then
    usage
fi
maf=$1

: ${SLURM_ARRAY_TASK_ID:=1}
: ${SLURM_JOB_ID:=1}

# Document software versions used for publication
if [ $SLURM_ARRAY_TASK_ID = 1 ]; then
    uname -a > Logs/3-filter/os-version-find-MAFs-$SLURM_JOB_ID.txt 2>&1
    bcftools --version > Logs/3-filter/bcftools-version-$SLURM_JOB_ID.txt
fi

hostname
pwd
which bcftools

if [ $SLURM_ARRAY_TASK_ID = 23 ]; then
    chr=X
else
    chr=$SLURM_ARRAY_TASK_ID
fi

filtered_dir=Data/3-filter/MAF-$maf
mkdir -p $filtered_dir
bcftools view -H -q ${maf}:minor \
    Data/Raw-bcfs/freeze.8.chr$chr.pass_only.phased.bcf \
    | mawk '{ print $2 }' > $filtered_dir/chr$chr-maf-sites.txt