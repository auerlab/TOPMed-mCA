#!/bin/sh -e

##########################################################################
#   Script description:
#       Find sites with MAF > 1%
#       This takes a couple days since it has to scan all the BCFs
#       Only needs to be run once and the results can be used for all
#       sample groups
#       
#   History:
#   Date        Name        Modification
#   2020-08-14  Jason Bacon Begin
##########################################################################

#SBATCH --array=1-23
#SBATCH --mem=200
#SBATCH --output=SLURM-outputs/find-maf-sites-%A_%a.out
#SBATCH --error=SLURM-outputs/find-maf-sites-%A_%a.err

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

if [ $SLURM_ARRAY_TASK_ID = 23 ]; then
    chr=X
else
    chr=$SLURM_ARRAY_TASK_ID
fi

filtered_dir=MAF-$maf
mkdir -p $filtered_dir
bcftools view -H -q ${maf}:minor \
    ../../phased/freeze.8.chr$chr.pass_only.phased.bcf \
    | awk '{ print $2 }' > $filtered_dir/chr$chr-maf-sites.txt
