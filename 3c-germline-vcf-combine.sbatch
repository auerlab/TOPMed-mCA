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

# Adjust the max jobs according to how much I/O your cluster can handle
#SBATCH --array=1-138134%20
#SBATCH --mem=500
#SBATCH --output=Logs/3-filter/gsv-combine-%A_%a.out
#SBATCH --error=Logs/3-filter/gsv-combine-%A_%a.err

: ${SLURM_ARRAY_TASK_ID:=1}

# These scripts were developed on a FreeBSD cluster where all software is
# installed via FreeBSD ports into the default PATH.  If you need to load
# an environment module, activate a conda environent, etc. to gain access
# to software used below, do it here.

# Document software versions used for publication
uname -a
which bcftools
bcftools --version
pwd

gsv_dir=Data/79852-germline-structural-variants/
vcf_dir=Data/3-filter/GSV-split-vcfs
done=0
samples=$(bcftools view $gsv_dir/sv.freeze1.chr9.gt.only.bcf | grep -m 1 '^#CHROM' | cut -f 10-)
printf "%s samples...\n" $(echo $samples | wc -w)

my_sample=$(echo $samples | awk -v n=$SLURM_ARRAY_TASK_ID '{ print $n }')
printf "Processing $my_sample...\n"

cd $vcf_dir
mkdir -p Combined
files=""
# No X chromosome in GSV data
for chr in $(seq 1 22); do
    files="$files chr$chr/chr$chr.$my_sample.vcf"
    chr=$((chr + 1))
done
combined=Combined/combined.$my_sample.vcf.xz
printf "===\n%u\nConcatenating $files to $combined...\n" $done
done=$((done + 1))
# Add only 1 copy of header
(head chr1/chr1.$my_sample.vcf | grep '^#' && grep --no-filename -v '^#' $files) | xz > $combined
bed=${combined%.vcf.xz}.bed
printf "$combined -> $bed...\n"
xzcat $combined | grep -v '^#' | mawk -f ../../../extract-range.awk > ${bed}
