#!/bin/sh -e

##########################################################################
#   Script description:
#       
#   History:
#   Date        Name        Modification
#   2019-12-08  Jason Bacon Begin
##########################################################################

# Notes:
#
# Filtering out calls with no het sites is probably useless with 137k
# samples per call.  Every call is likely to have at least one het site.
# Does not seem to work in conjunction with --samples.
# --samples NWDXXXX --genotype het produces lines with 1|1 or 0|0.
# Maybe checking all samples for het instead of just selected samples?
#
# vcftools is much slower than bcftools

# From bcf-bench:
# --min-ac + --genotype about doubles run time
# --min-ax + --samples increases run time by order of magnitude

##########################################################################
# vcf-split is limited by the number of open files your filesystem can
# write at once.  Tens of thousands are usually feasible on a high-end
# server.
# Keep in mind that they add up with parallel jobs accessing the same
# file server. Output initially to compute node local disk and use
#
#   #SBATCH --ntasks-per-node=1
#
# to get past this limit.

#SBATCH --array=1-23 --cpus-per-task=2
#SBATCH --mem=300
#SBATCH --output=Logs/1-vcf-split/vcf-split-%A_%a.out
#SBATCH --error=Logs/1-vcf-split/vcf-split-%A_%a.err

# If running outside scheduler, SLURM_ARRAY_TASK_ID will not be set.
# Create a dummy task ID of 21 for single-sample testing on dev server.
# 21 is the smallest of the chromosomes for which errors were reported
: ${SLURM_ARRAY_TASK_ID:=21}

# Document software versions used for publication
if [ $SLURM_ARRAY_TASK_ID = 1 ]; then
    uname -a > Logs/1-vcf-split/os-version-$SLURM_JOB_ID.txt 2>&1
    # vcf-split --version > Logs/1-vcf-split/vcf-split-version-$SLURM_JOB_ID.txt 2>&1
fi

hostname
pwd
which bcftools vcf-split

# Make output file names sort lexically by chromosome number
if [ $SLURM_ARRAY_TASK_ID = 23 ]; then
    one_digit_chrom=X
    two_digit_chrom=X
else
    one_digit_chrom=$SLURM_ARRAY_TASK_ID
    two_digit_chrom=$(printf "%02d" $SLURM_ARRAY_TASK_ID)
fi

bcf=freeze.8.chr$one_digit_chrom.pass_only.phased.bcf
printf "Splitting VCF for chromosome $two_digit_chrom...\n"

cd Data

# Organize by chromosome to reduce # of files in each dir
output_dir=1-vcf-split/chr$two_digit_chrom
mkdir -p $output_dir
sample_id_file=samples.txt
# More than 10k open files will generally reduce CPU utilization
max_samples=1000
if [ $(cat $sample_id_file | wc -l) -gt $max_samples ]; then
    cat << EOM
    
$sample_id_file contains too many samples.  Please limit to $max_samples
to prevent overloading the disk.

EOM
    exit 1
fi

bcftools view --min-ac 2 --exclude-types indels Raw-bcfs/$bcf \
    | vcf-split --het-only --sample-id-file samples.txt \
    --fields chrom,pos,ref,alt,format \
    $output_dir/chr$two_digit_chrom. 1 137977

