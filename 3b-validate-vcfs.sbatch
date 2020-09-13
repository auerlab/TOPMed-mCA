#!/bin/sh -e

#SBATCH --array=1-6
#SBATCH --output=SLURM-outputs/validate-vcfs-%A_%a.out
#SBATCH --error=SLURM-outputs/validate-vcfs-%A_%a.err

##########################################################################
#   Script description:
#       Validate structure of AD-enhanced VCFs before running haplohseq
#       This is redundant since each VCF is validated the same way on
#       AWS after ad2vcf completes
#       
#   History:
#   Date        Name        Modification
#   2020-09-13  Jason Bacon Begin
##########################################################################

usage()
{
    printf "Usage: $0 sample-group (e.g. whi, bjm)\n"
    exit 1
}


##########################################################################
#   Main
##########################################################################

if [ $# != 1 ]; then
    usage
fi
sample_group=$1

: ${SLURM_ARRAY_TASK_ID:=1}

my_list=`printf "AD-VCFs-%s/vcfs-%02s" $sample_group $((SLURM_ARRAY_TASK_ID - 1))`
printf "Processing $my_list on $(hostname)...\n"

corrupt_vcfs="corrupt-vcfs-$sample_group.txt"

for file in $(cat $my_list); do
    printf "$file "
    last_line=$(xzcat $file | tail -n 1)
    cols=$(echo $last_line | awk '{ print NF }')
    if [ $cols != 10 ]; then
	printf "\nLast line in $file has $cols columns, should be 10.\n" \
	    >> $corrupt_vcfs
    else
	last_field=$(echo $last_line | awk '{ print $10 }')
	ad=$(echo $last_field | awk -F : '{ print $2 }')
	ref=$(echo $ad | awk -F , '{ print $1 }')
	alt=$(echo $ad | awk -F , '{ print $2 }')
	dp=$(echo $last_field | awk -F : '{ print $3 }')
	if [ $((ref + alt)) != $dp ]; then
	    printf "\nref + alt != dp\n" >> $corrupt_vcfs
	else
	    printf "OK\n"
	fi
    fi
done
