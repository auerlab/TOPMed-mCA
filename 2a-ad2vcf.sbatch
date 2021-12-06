#!/bin/sh -e

##########################################################################
#
#   This script was not used in the primary analysis, since it was not
#   feasible to download the necessary CRAM files, which totalled
#   around 1.5 petabytes.
#
#   ad2vcf was run on AWS, where the CRAM files were accessed using
#   Fusera (now obsolete) using the scripts in the SRA directory.
#   Sra-tools 1.10 or later should be able to access the CRAMs on AWS.
#       
#   All necessary tools are assumed to be in PATH.  If this is not
#   the case, add whatever code is needed here to gain access.
#   (Adding such code to your .bashrc or other startup script is
#   generally a bad idea since it's too complicated to support
#   every program with one environment.)
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
uname -a
which samtools ad2vcf
samtools --version
ad2vcf --version
pwd

# Make sure --array above matches the # of samples
my_sample=$(./select-sample.sh $SLURM_ARRAY_TASK_ID)
printf "Processing $my_sample...\n"

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
