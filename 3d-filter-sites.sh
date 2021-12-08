#!/bin/sh -e

##########################################################################
#
#   Filter sites for minimum allele frew (MAF) and minimum distance
#   from each other
#       
#   All necessary tools are assumed to be in PATH.  If this is not
#   the case, add whatever code is needed here to gain access.
#   (Adding such code to your .bashrc or other startup script is
#   generally a bad idea since it's too complicated to support
#   every program with one environment.)
#
#   History:
#   Date        Name        Modification
#   2020-09-13  Jason Bacon Begin
##########################################################################

usage()
{
    printf "Usage: $0 min-allele-frequency min-separation\n"
    printf "Example: $0 0.05 1000\n"
    exit 1
}


##########################################################################
#   Main
##########################################################################

if [ $# != 2 ]; then
    usage
fi
maf=$1              # Minimum allele frequency
separation=$2       # Min distance between events

if [ ! -d Data/3-filter/MAF-sites-$maf ]; then
    printf "Missing MAF-sites-$maf directory.\n"
    printf "Run 3a-find-maf-sites.sbatch first or specify MAF correctly.\n"
    exit 1
fi

# Filter using database of genomic variants
# dgv_gff=DGV.GS.hg38.gff3
# if [ ! -e $dgv_gff ]; then
#     curl -O http://dgv.tcag.ca/dgv/docs/$dgv_gff
# fi

vcf_dir=Data/2-ad2vcf
vcf_list=$vcf_dir/VCF-list.txt

ls $vcf_dir | grep '.*-ad\.vcf\.xz' > $vcf_list
sample_count=$(cat $vcf_list | wc -l)
sample_count=$(printf "%d" $sample_count)   # Strip leading space
printf "Samples: $sample_count\n"

# Only for comparison to see the effects of DGV filtering
# mkdir -p $vcf_dir/MAF-$maf-${separation}nt

mkdir -p $vcf_dir/MAF-$maf-${separation}nt-sv

sbatch --array=1-$sample_count%20 3d-filter-sites.sbatch $maf $separation
