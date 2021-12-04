#!/bin/sh -e

#SBATCH --mem=500
#SBATCH --output=Logs/3-filter/gsv-split-%A_%a.out
#SBATCH --error=Logs/3-filter/gsv-split-%A_%a.err

##########################################################################
#
#   Split germline structural event BCFs, outputting only specified
#   samples and only those containing an ALT allele (1 in either copy)
#       
#   All necessary tools are assumed to be in PATH.  If this is not
#   the case, add whatever code is needed here to gain access.
#   (Adding such code to your .bashrc or other startup script is
#   generally a bad idea since it's too complicated to support
#   every program with one environment.)
#
#   History:
#   Date        Name        Modification
#   2021-02-20  Jason Bacon Begin
##########################################################################

hostname
which bcftools vcf-split

uname -a > Logs/3-filter/os-version-gsv-split.txt 2>&1
bcftools --version > Logs/3-filter/bcftools-version-gsv-split.txt
vcf-split --version > Logs/3-filter/vcf-split-version-gsv-split.txt
ls Logs/3-filter

# 79852-germline-structural-variants must contain the appopriate BCF files
# matching the raw phased BCFs used in earlier steps.
gsv_dir=Data/79852-germline-structural-variants
total_samples=$(bcftools view $gsv_dir/sv.freeze1.chr9.gt.only.bcf | grep -m 1 '^#CHROM' | awk '{ print NF-9 }')
printf "Total samples = $total_samples\n"

output_dir=Data/3-filter/GSV-split-vcfs
mkdir -p $output_dir
for file in $gsv_dir/sv.freeze1.*.gt.only.bcf; do
    chr=$(echo $file | cut -d . -f 3)
    mkdir -p $output_dir/$chr
    for first_col in $(seq 1 10000 $total_samples); do
	last_col=$(( first_col + 9999 ))
	test $last_col -gt $total_samples && last_col=$total_samples
	printf "Processing $file columns $first_col to $last_col...\n"
	bcftools view $file \
	    | vcf-split --alt-only --fields chrom,id,pos,format \
		$output_dir/$chr/$chr. $first_col $last_col
    done
done
