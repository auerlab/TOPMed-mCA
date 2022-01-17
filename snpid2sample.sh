#!/bin/sh

svdir=Data/79852-germline-structural-variants
for c in $(seq 21 21); do
    printf "chr$c\n"
    id_str=$(awk -v chr=chr$c '$1 == chr { printf("%s ", $3); }' \
	67cbf3a8-output.filtered.001)
    printf '\n'
    
    bcftools view -H $svdir/sv.freeze1.chr$c.gt.only.bcf \
	| mawk -v id_str="$id_str" -f snpid2sample.awk
done
