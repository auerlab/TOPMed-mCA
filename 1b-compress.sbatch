#!/bin/sh -e

##########################################################################
#
#   SLURM script for compressing VCF outputs.
#
#   Do not submit this script directly.  Use 1b-compress.sh.
#       
#   History:
#   Date        Name        Modification
#   2021-11-29  Jason Wayne BaconBegin
##########################################################################

#SBATCH --output=Logs/1b-compress/compress-%A_%a.out
#SBATCH --error=Logs/1b-compress/compress-%A_%a.err

# Set a default value for testing outside the SLURM environment
: ${SLURM_ARRAY_TASK_ID:=1}

# These scripts were developed on a FreeBSD/SPCM cluster where all software is
# installed via FreeBSD ports into the default PATH.  If you need to load
# an environment module, activate a conda environent, etc. to gain access
# to software used below, do it here.

# Document software versions used for publication
uname -a
which xz
pwd

cd Data/1b-compress

# Pick a sample from the list based on SLURM_ARRAY_TASK_ID
split_file_num=$(( ($SLURM_ARRAY_TASK_ID - 1) / 1000 ))
split_file=$(printf "vcf-list-%04d" $split_file_num)
line=$(( ($SLURM_ARRAY_TASK_ID - 1) % 1000 + 1 ))
my_vcf=$(awk -v line=$line 'NR == line { print $1 }' $split_file)

printf "Compressing $my_vcf...\n"
xz -f $my_vcf
rm $my_vcf.done
