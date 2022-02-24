#!/bin/sh -e

##########################################################################
#   Script description:
#       SLURM script for concatenating single-chromosome VCFs.
#
#       Do not submit this script directly.  Use 1c-combine.sh.
#       
#   History:
#   Date        Name        Modification
#   2021-11-29  Jason Wayne BaconBegin
##########################################################################

#SBATCH --mem=200
#SBATCH --output=Logs/1c-combine/combine-%A_%a.out
#SBATCH --error=Logs/1c-combine/combine-%A_%a.err

# Set a default value for testing outside the SLURM environment
: ${SLURM_ARRAY_TASK_ID:=1}

# These scripts were developed on a FreeBSD/SPCM cluster where all software is
# installed via FreeBSD ports into the default PATH.  If you need to load
# an environment module, activate a conda environent, etc. to gain access
# to software used below, do it here.

# Document software versions used for publication
uname -a
which xzcat
pwd

my_sample=$(./select-sample.sh $SLURM_ARRAY_TASK_ID)

cd Data/1c-combine

sources=$(ls ../1b-compress/chr*/chr*.$my_sample.vcf.xz)
printf "Combining:\n$sources...\n"

# Strip headers from all but first file
# Replace "SAMPLE" in header with actual sample ID
# This should have been done by vcf-split, but re-running is expensive
(xzcat ../1b-compress/chr01/chr*.$my_sample.vcf.xz | grep '^#' | sed -e "s|SAMPLE|$my_sample|g"
for file in $sources; do
    xzcat $file | grep -v '^#'
done) | xz -cf > combined.$my_sample.vcf.xz
