#!/bin/sh -e

##########################################################################
#   Script description:
#       Filter sites for minor allele frequency (MAF) and minimum
#       distance from each other
#       
#   History:
#   Date        Name        Modification
#   2020-09-13  Jason Bacon Begin
##########################################################################

usage()
{
    printf "Usage: $0 sample-group MAPQ-min min-allele-frequency min-separation\n"
    printf "Example: $0 whi 0 0.005\n"
    exit 1
}


##########################################################################
#   Main
##########################################################################

if [ $# != 3 ]; then
    usage
fi
sample_group=$1
mapq_min=$2
maf=$3              # Minor allele frequency

if [ ! -d MAF-$maf ]; then
    printf "Missing MAF-$maf directory.\n"
    printf "Run 3c-find-maf-sites.sbatch first or specify MAF correctly.\n"
    exit 1
fi

# Filter using database of genomic variants
# dgv_gff=DGV.GS.hg38.gff3
# if [ ! -e $dgv_gff ]; then
#     curl -O http://dgv.tcag.ca/dgv/docs/$dgv_gff
# fi

vcf_dir=AD-VCFs-$sample_group-MAPQ-$mapq_min
vcf_list=$vcf_dir/VCF-list.txt

ls $vcf_dir | grep '.*-ad\.vcf\.xz' > $vcf_list
sample_count=$(cat $vcf_list | wc -l)
sample_count=$(printf "%d" $sample_count)   # Strip leading space
printf "Samples: $sample_count\n"

# Only for comparison to see the effects of DGV filtering
# mkdir -p $vcf_dir/MAF-$maf-${separation}nt

mkdir -p $vcf_dir/MAF-$maf
sbatch --array=1-$sample_count%50 \
    4a-matrix-filter-sites.sbatch $sample_group $mapq_min $maf
