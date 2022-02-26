#!/bin/sh -e

#SBATCH --array=1-22    # X chromosome
#SBATCH --mem=1000
#SBATCH --output=Logs/3b-germline-split/gsv-split-%A_%a.out
#SBATCH --error=Logs/3b-germline-split/gsv-split-%A_%a.err

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

# These scripts were developed on a FreeBSD/SPCM cluster where all software is
# installed via FreeBSD ports into the default PATH.  If you need to load
# an environment module, activate a conda environent, etc. to gain access
# to software used below, do it here.

# Document software versions used for publication
uname -a
which bcftools
which vcf-split
bcftools --version
vcf-split --version
pwd

: ${SLURM_ARRAY_TASK_ID:=1}

# 79852-germline-structural-variants must contain the appopriate BCF files
# matching the raw phased BCFs used in earlier steps.
gsv_dir=Data/79852-germline-structural-variants
sleep $SLURM_ARRAY_TASK_ID  # Offset reading of the BCF
total_samples=$(bcftools view $gsv_dir/sv.freeze1.chr9.gt.only.bcf | grep -m 1 '^#CHROM' | awk '{ print NF-9 }')
printf "Total samples = $total_samples\n"

chr=chr$SLURM_ARRAY_TASK_ID
output_dir=Data/3b-germline-split/GSV-split-vcfs/$chr
file=$gsv_dir/sv.freeze1.$chr.gt.only.bcf

mkdir -p $output_dir
for first_col in $(seq 1 10000 $total_samples); do
    last_col=$(( first_col + 9999 ))
    test $last_col -gt $total_samples && last_col=$total_samples
    printf "Processing $file columns $first_col to $last_col...\n"
    bcftools view $file \
	| vcf-split --alt-only --fields chrom,id,pos,format \
	    $output_dir/$chr. $first_col $last_col
done
