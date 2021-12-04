#!/bin/sh -e

##########################################################################
#
#   Concatenate germline structural event BCFs, only those containing
#   an ALT allele ('1' in either copy)
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

#SBATCH --mem=500
#SBATCH --output=Logs/3-filter/gsv-concat-%A.out
#SBATCH --error=Logs/3-filter/gsv-concat-%A.err

hostname
uname -a > Logs/3-filter/os-version-gsv-split.txt 2>&1

gsv_dir=Data/79852-germline-structural-variants/
vcf_dir=Data/3-filter/GSV-split-vcfs
done=0
samples=$(bcftools view $gsv_dir/sv.freeze1.chr9.gt.only.bcf | grep -m 1 '^#CHROM' | cut -f 10-)
printf "Concatenating %s samples...\n" $(echo $samples | wc -w)

cd $vcf_dir
mkdir -p Combined
for sample in $samples; do
    files=""
    # No X chromosome in GSV data
    for chr in $(seq 1 22); do
	files="$files chr$chr/chr$chr.$sample.vcf"
	chr=$((chr + 1))
    done
    combined=Combined/combined.$sample.vcf.xz
    printf "===\n%u\nConcatenating $files to $combined...\n" $done
    done=$((done + 1))
    # Add only 1 copy of header
    (head chr1/chr1.$sample.vcf | grep '^#' && grep --no-filename -v '^#' $files) | xz > $combined
    bed=${combined%.vcf.xz}.bed
    printf "$file -> $bed...\n"
    xzcat $file | grep -v '^#' | mawk -f ../../extract-range.awk > ${bed}
done
