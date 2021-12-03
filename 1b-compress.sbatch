#!/bin/sh -e

##########################################################################
#   Script description:
#       SLURM script for compressing VCF outputs.
#
#       Do not run this script directly.  Use 1b-compress.sh
#       
#   History:
#   Date        Name        Modification
#   2021-11-29  Jason Wayne BaconBegin
##########################################################################

#SBATCH --output=Logs/1-vcf-split/compress-%A_%a.out
#SBATCH --error=Logs/1-vcf-split/compress-%A_%a.err

# Set a default value for testing outside the SLURM environment
: ${SLURM_ARRAY_TASK_ID:=1}
: ${SLURM_JOB_ID:=1}

# Record software versions
if [ $SLURM_ARRAY_TASK_ID = 1 ]; then
    uname -a > Logs/1-vcf-split/os-version-compress-$SLURM_JOB_ID.txt 2>&1
fi

hostname

cd Data/1-vcf-split

# Pick a sample from the list based on SLURM_ARRAY_TASK_ID
split_file_num=$(( ($SLURM_ARRAY_TASK_ID - 1) / 1000 ))
split_file=$(printf "vcf-list-%04d" $split_file_num)
line=$(( ($SLURM_ARRAY_TASK_ID - 1) % 1000 + 1 ))
my_vcf=$(awk -v line=$line 'NR == line { print $1 }' $split_file)

printf "Compressing $my_vcf...\n"
xz -f $my_vcf
rm $my_vcf.done
