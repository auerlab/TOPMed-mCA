#!/bin/sh -e

#SBATCH --array=1-22    # Samples, not chromosomes
#SBATCH --ntasks=4      # 3 for samtools, 1 for ad2vcf
#SBATCH --mem=500       # Mostly for samtools, ad2vcf uses about 5M

# Uncomment to use latest test build, otherwise use ad2vcf in PATH
export PATH=../../local/bin:${PATH}
which ad2vcf

# Arbitrary index for testing outside SLURM
: ${SLURM_ARRAY_JOB_ID:=2}

crams=$(ls ../../SRR6990379/*.cram | cut -d / -f 4 | cut -d . -f 1)
my_sample=$(echo $samples | awk -v index=$SLURM_ARRAY_JOB_ID '{ print $index }')
echo $my_sample

# Make sure hts-ref is fully populated before running parallel jobs that
# might attempt redundant downloads
/usr/bin/time samtools view -@ $threads \
    --input-fmt-option required_fields=0x208 \
    ../../SRR6990379/$sample.b38.irc.v1.cram \
    | ad2vcf Split-vcfs/Combined/combined.$sample.vcf.xz

