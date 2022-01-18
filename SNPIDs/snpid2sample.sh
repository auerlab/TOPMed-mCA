#!/bin/sh -e

##########################################################################
#   Script description:
#       Search structural variant BCF files for variants matching the
#       SNPID in 67cbf3a8-output.filtered.001.  Report back sample IDs
#       for samples with at least one variant allele, i.e. 0/1, 1/0, or
#       1/1.
#       
#   History:
#   Date        Name        Modification
#   2022-01-17  Jason Wayne BaconBegin
##########################################################################

usage()
{
    printf "Usage: $0 \n"
    exit 1
}


##########################################################################
#   Main
##########################################################################

if [ $# != 0 ]; then
    usage
fi

rm -f snpids.txt
svdir=../Data/79852-germline-structural-variants
for c in $(seq 1 22); do
    printf "chr$c\n"
    id_str=$(awk -v chr=chr$c '$1 == chr { printf("%s ", $3); }' \
	67cbf3a8-output.filtered.001)
    
    bcftools view $svdir/sv.freeze1.chr$c.gt.only.bcf \
	| mawk -v id_str="$id_str" -f snpid2sample.awk >> snpids.tsv
done
