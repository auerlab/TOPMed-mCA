#!/bin/sh -e

# Peregrine: Getting stale NFS handles on xzcat | sed with %24 or more
# Probably timeouts from too much NFS load for the 1G network
# Using local /tmp for uncompressed files eliminated the issue
#SBATCH --array=1-2765%50
#SBATCH --mem=1g
#SBATCH --output=SLURM-outputs/haplohseq-%A_%a.out
#SBATCH --error=SLURM-outputs/haplohseq-%A_%a.err

# Dummy value for testing outside SLURM env
: ${SLURM_ARRAY_TASK_ID:=1}

# ad2vcf outputs from Josh
vcf_dir=Filtered-vcfs
cd $vcf_dir

output_dir=Haplo-output
tmp_dir=/tmp/haplohseq-$SLURM_ARRAY_JOB_ID
# FIXME: rmdir $tmp_dir as post-processing
mkdir -p $output_dir $tmp_dir

filename=$(ls combined*-ad-*.vcf.xz | \
    awk -v i=$SLURM_ARRAY_TASK_ID 'NR == i { print $0 }')
uncompressed=$tmp_dir/${filename%.xz}
filename_prefix=`echo $filename | cut -d - -f 1`
sample=${filename_prefix#combined.}
hostname
printf "$filename $uncompressed $filename_prefix $sample $output_dir\n"

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
