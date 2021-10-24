#!/bin/sh -e

# Known present in WHI
chr=chr1
pos=758351

# From Paul's email
chr=chr2
pos=178436244

for group in bjm whi group3 group4; do
    for dir in SRA/VCFs-$group-samples-*; do
	echo $dir
	for file in $dir/Done-MAPQ-0/*.xz; do
	    sample=$(echo $file | awk -F '[-.]' '{ print $7 }')
	    # xzcat $file | ./vcf-search-chr-pos $chr $pos
	    xzcat $file | mawk -v sample=$sample -v chr=$chr -v pos=$pos \
		'$1 == chr && $2 == pos { printf("%s\t%s\n", sample, $0); }'
	done
    done
done
