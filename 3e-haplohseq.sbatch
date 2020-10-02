#!/bin/sh -e

# Peregrine: Getting stale NFS handles on xzcat | sed with %24 or more
# Probably timeouts from too much NFS load for the 1G network
# Using local /tmp for uncompressed files eliminated the issue
#SBATCH --mem=1g
#SBATCH --output=SLURM-outputs/haplohseq-%A_%a.out
#SBATCH --error=SLURM-outputs/haplohseq-%A_%a.err

##########################################################################
#   Script description:
#       Run haplohseq on all .vcf.xz files in a directory
#       Don't run this directly:
#       Use
#           ./3d-haplohseq $dir
#
#   History:
#   Date        Name        Modification
#   2020-09-13  Jason Bacon Begin
##########################################################################

usage()
{
    printf "Usage: $0 ad-vcf-dir\n"
    exit 1
}


##########################################################################
#   Main
##########################################################################

if [ $# != 1 ]; then
    usage
fi
vcf_dir=$1

# Dummy value for testing outside SLURM env
: ${SLURM_ARRAY_TASK_ID:=1}

cd $vcf_dir
output_dir=Haplo-output
mkdir -p $output_dir

# Using ls here was resulting in some jobs getting the same filename for
# some reason.  It's a weird NFS issue where directory listing are missing
# some files or files are added when under heavy load. Denerate a static list
# VCF-list.txt in the calling script and use it here.
# Same results using find or ls|grep
# Works OK on NFSv3 but fails on 4.
# ls | grep 'combined.*-ad\.vcf\.xz' > $output_dir/list-$SLURM_ARRAY_TASK_ID.txt
# filename=$(ls | grep 'combined.*-ad\.vcf\.xz' \
#     | awk -v i=$SLURM_ARRAY_TASK_ID 'NR == i { print $0 }')
# This works fine and saves time when NFS is heavily loaded
filename=$(awk -v i=$SLURM_ARRAY_TASK_ID 'NR == i { print $0 }' VCF-list.txt)
# Use local disk for uncompressed files to offload NFS
uncompressed=/tmp/${filename%.xz}
filename_prefix=`echo $filename | cut -d - -f 1`
sample=${filename_prefix##*.}
hostname
printf "TASK ID:      $SLURM_ARRAY_TASK_ID\n"
printf "Filename:     $filename\n"
printf "Uncompressed: $uncompressed\n"
printf "Prefix:       $filename_prefix\n"
printf "Sample:       $sample\n"
printf "Output dir:   $output_dir\n"

# ../../../local/bin version should be built with portable optimizations
# On FreeBSD, can also use ports version optimized for each compute node
# export PATH=../../../../local/bin:$PATH
which vcf2hap haplohseq

printf "Uncompressing...\n"
# Peregrine: xzcat is causing intermittent failures in vcf2hap
# Examining the files later shows they are all OK
# The problem only occurs shortly after xzcat completes
# xzcat < $filename > $uncompressed
# Same issue does not occur when using unxz
# Buffering issue when using redirection?  Does stdout pass through SLURM?
# Removing $uncompressed beforehand fixes the issue
rm -f $uncompressed
xzcat < $filename | sed -E 's|,[0-9]+:|:|' > $uncompressed
sync

# Generate hap file from VCF
printf "\nSTEP 1: GENERATING HAPLOTYPE FILES...\n"
printf "Generating .hap file...\n"
vcf2hap $sample < $uncompressed > $filename_prefix-ad.hap
sync

# Identify allelic imbalance (AI) given a tumor
# exome VCF file generated using the UnifiedGenotyper
# of the GATK. This involves the following 3 steps.

# Our files are already phased
# printf "STEP 1: PHASING 1KG HET SITES ...\n"
# python ../scripts/simple_phaser.py \
#  --ldmap ../ldmap/hg19.exome.ldmap \
#  --vcf example_input/tumor_exome.vcf \
#  -o example_output/tumor_exome

# prevelance = 0.01 per Paul Scheet
printf "\nSTEP 2: IDENTIFYING REGIONS OF AI ...\n"
if [ -e $output_dir/$filename_prefix.posterior.dat ]; then
    printf "haplohseq already done.\n"
else
    time haplohseq \
	--vcf $uncompressed \
	--phased $filename_prefix-ad.hap \
	--event_prevalence 0.01 \
	-d $output_dir \
	-p $filename_prefix
fi

# Save space
rm -f $uncompressed $filename_prefix-ad.hap
exit 0

# Should not be needed
if [ -e $output_dir/${filename}_haplohseq.png ]; then
    printf "Plotting already done.\n"
else
    printf "\nSTEP 3: PLOTTING HAPLOHSEQ GENOMIC AI PROFILE ...\n"
    time Rscript /usr/local/share/examples/haplohseq/scripts/haplohseq_plot.R \
	--file $output_dir/$filename_prefix.posterior.dat \
	--out $output_dir \
	--prefix ${filename}_haplohseq
fi
