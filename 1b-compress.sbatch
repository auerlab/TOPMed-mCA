#!/bin/sh -e

#SBATCH --output=Logs/1-vcf-split/compress-%A_%a.out
#SBATCH --error=Logs/1-vcf-split/compress-%A_%a.err

cd Data/1-vcf-split

split_file_num=$(( (SLURM_ARRAY_TASK_ID - 1) / 1000 ))
split_file=$(printf "vcf-list-%04d" $split_file_num)
line=$(( (SLURM_ARRAY_TASK_ID - 1) % 1000 + 1 ))
my_vcf=$(awk -v line=$line 'NR == line { print $1 }' $split_file)

printf "Compressing $my_vcf...\n"
xz -f $my_vcf
