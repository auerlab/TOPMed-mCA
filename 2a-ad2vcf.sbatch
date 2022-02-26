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
#   Each ad2vcf task took about 20 minutes on my workstation and about 30
#   minutes on AWS using an AMD Epyc instance.
#
#   Do not submit this script directly.  Use 2a-ad2vcf.sh.
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

#SBATCH --cpus-per-task=3
#SBATCH --mem=1g
#SBATCH --output=Logs/2a-ad2vcf/ad2vcf-%A_%a.out
#SBATCH --error=Logs/2a-ad2vcf/ad2vcf-%A_%a.err

: ${SLURM_ARRAY_TASK_ID:=1}

# These scripts were developed on a FreeBSD/SPCM cluster where all software is
# installed via FreeBSD ports into the default PATH.  If you need to load
# an environment module, activate a conda environent, etc. to gain access
# to software used below, do it here.

# Document software versions used for publication
uname -a
which samtools
which ad2vcf
samtools --version
ad2vcf --version
pwd

# Make sure --array above matches the # of samples
my_sample=$(./select-sample.sh $SLURM_ARRAY_TASK_ID)
printf "Processing $my_sample...\n"

cd Data/2a-ad2vcf
hostname
pwd
which ad2vcf

mapq_min=10
printf "Processing $my_sample...\n"
# ad2vcf will place the augmented VCF in the same dir as the source, so
# create a temporary symlink in current working directory
ln -sf ../1c-combine/combined.$my_sample.vcf.xz .
set -x
# Filter out unmapped, secondary, qcfail, dup, and supplementary alignments
# using --excl-flags.  This prevents ad2vcf from buffering too many
# alignments for samples with many duplicates.  This is rare, but some
# outlier samples may buffer nearly a million reads.
# This was not done for the primary analysis, but should not change the
# results much.
samtools view -@ 2 \
    --input-fmt-option required_fields=0x218 \
    --excl-flags 0xF0C \
    ../Alignments/$my_sample.b38.irc.v1.cram \
    | ad2vcf combined.$my_sample.vcf.xz $mapq_min

# Remove the temporary symlink
rm combined.$my_sample.vcf.xz
