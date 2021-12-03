#!/bin/sh -e

##########################################################################
#   Script description:
#
#       This script was not used in the analysis, since the necessary
#       CRAM files were not available on a cluster.
#
#       ad2vcf was run on AWS using the scripts in the SRA directory.
#       
#   History:
#   Date        Name        Modification
#   2021-12-02  Jason Wayne BaconBegin
##########################################################################

#SBATCH --array=1-23%100
#SBATCH --cpus-per-task=3
#SBATCH --mem=1g
#SBATCH --output=Logs/2-ad2vcf/ad2vcf-%A_%a.out
#SBATCH --error=Logs/2-ad2vcf/ad2vcf-%A_%a.err

: ${SLURM_ARRAY_TASK_ID:=12}
: ${SLURM_JOB_ID:=1}

# Document software versions used for publication
if [ $SLURM_ARRAY_TASK_ID = 1 ]; then
    uname -a > Logs/2-ad2vcf/os-version-$SLURM_JOB_ID.txt 2>&1
    samtools --version > Logs/2-ad2vcf/samtools-version-$SLURM_JOB_ID.txt 2>&1
    ad2vcf --version > Logs/2-ad2vcf/ad2vcf-version-$SLURM_JOB_ID.txt 2>&1
fi

# Make sure --array above matches the # of samples
my_sample=$(./select-sample.sh $SLURM_ARRAY_TASK_ID)
echo $my_sample

cd Data/2-ad2vcf
hostname
pwd
which ad2vcf

printf "Processing $my_sample...\n"
# ad2vcf will place the augmented VCF in the same dir as the source
ln -sf ../1-vcf-split/Combined/combined.$my_sample.vcf.xz .
set -x
# Filter out unmapped, secondary, qcfail, dup, and supplementary alignments
# This was not done for the primary analysis
samtools view -@ 2 \
    --input-fmt-option required_fields=0x218 \
    --excl-flags 0xF0C \
    ../Alignments/$my_sample.b38.irc.v1.cram \
    | ad2vcf combined.$my_sample.vcf.xz 10
rm combined.$my_sample.vcf.xz
