#!/bin/sh -e

#SBATCH --array=1-4

: ${SLURM_ARRAY_TASK_ID:=2}

groups="bjm whi group3 group4"
group=$(echo $groups | awk -v task=$SLURM_ARRAY_TASK_ID '{ print $task }')

# Known present in WHI
chr=chr1
pos=758351

# From Paul's email
chr=chr2
pos=178436244

for dir in SRA/VCFs-$group-samples-*; do
    echo $dir
    for file in $dir/Done-MAPQ-0/*.xz; do
	sample=$(echo $file | awk -F '[-.]' '{ print $7 }')
	# xzcat $file | ./vcf-search-chr-pos $chr $pos
	xzcat $file | mawk -v sample=$sample -v chr=$chr -v pos=$pos \
	    '$1 == chr && $2 == pos { printf("%s\t%s\n", sample, $0); }'
    done
done
