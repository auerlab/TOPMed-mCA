#!/bin/sh -e

##########################################################################
#   Script description:
#       Find sites with MAF > 1%
#       
#   History:
#   Date        Name        Modification
#   2020-08-14  Jason Bacon Begin
##########################################################################

#SBATCH --array=1-23
#SBATCH --mem=200

: ${SLURM_ARRAY_TASK_ID:=1}

if [ $SLURM_ARRAY_TASK_ID = 23 ]; then
    chr=X
else
    chr=$SLURM_ARRAY_TASK_ID
fi

bcftools view -H -q 0.01:minor \
    ../../../phased/freeze.8.chr$chr.pass_only.phased.bcf \
    | awk '{ print $2 }'
