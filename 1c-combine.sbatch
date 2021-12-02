#!/bin/sh -e

##########################################################################
#   Script description:
#       SLURM script for concatenating single-chromosome VCFs.
#
#       Do not run this script directly.  Use 1c-combine.sh.
#       
#   History:
#   Date        Name        Modification
#   2021-11-29  Jason Wayne BaconBegin
##########################################################################

#SBATCH --mem=200
#SBATCH --output=Logs/1-vcf-split/combine-%A_%a.out
#SBATCH --error=Logs/1-vcf-split/combine-%A_%a.err

# Set a default value for testing outside the SLURM environment
: ${SLURM_ARRAY_TASK_ID:=1}

hostname

cd Data/1-vcf-split

# Pick a sample from the list based on SLURM_ARRAY_TASK_ID
max_lines=$(cat sample-list-0000 | wc -l)
split_file_num=$(( ($SLURM_ARRAY_TASK_ID - 1) / $max_lines ))
split_file=$(printf "sample-list-%04d" $split_file_num)
line=$(( ($SLURM_ARRAY_TASK_ID - 1) % $max_lines + 1 ))
my_sample=$(awk -v line=$line 'NR == line { print $1 }' $split_file)

sources=$(ls chr*/chr*.$my_sample.vcf.xz)
printf "Combining:\n$sources...\n"

# Strip headers from all but first file
# Replace "SAMPLE" in header with actual sample ID
# This should have been done by vcf-split, but re-running is expensive
(xzcat chr01/chr*.$my_sample.vcf.xz | grep '^#' | sed -e "s|SAMPLE|$my_sample|g"
for file in $sources; do
    xzcat $file | grep -v '^#'
done) | xz -cf > Combined/combined.$my_sample.vcf.xz
