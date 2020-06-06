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

##SBATCH --array=1-23 --cpus-per-task=2
#SBATCH --array=1-13 --cpus-per-task=2
#SBATCH --mem=300
#SBATCH --output=SLURM-outputs/vcf-split-%A_%a.out
#SBATCH --error=SLURM-outputs/vcf-split-%A_%a.err
#SBATCH --exclude=compute-[001-008,012]

# If running outside scheduler, SLURM_ARRAY_TASK_ID will not be set.
# Create a dummy task ID of 21 for single-sample testing on dev server.
# 21 is the smallest of the chromosomes for which errors were reported
: ${SLURM_ARRAY_TASK_ID:=21}

# If using Mortimer pkgsrc
if [ -e /raid-01/UITS/bacon/Pkgsrc/pkg-2019Q4 ]; then
    source /etc/bashrc
    module load /raid-01/UITS/bacon/Pkgsrc/pkg-2019Q4/etc/modulefiles/pkgsrc/2019Q4
fi

# ../../../local/bin version should be built with portable optimizations
# On FreeBSD, can also use ports version optimized for each compute node
export PATH=../../local/bin:$PATH
which bcftools vcf-split

# Make output file names sort lexically by chromosome number
if [ $SLURM_ARRAY_TASK_ID = 23 ]; then
    chromosome=X
    bcf=freeze.8.chrX.pass_only.phased.bcf
else
    chromosome=$(printf "%02d" $SLURM_ARRAY_TASK_ID)
    bcf=freeze.8.chr$SLURM_ARRAY_TASK_ID.pass_only.phased.bcf
fi
printf "Splitting VCF for chromosome $chromosome...\n"

# Organize by chromosome to reduce # of files in each dir
output_dir=Split-vcfs/chr$chromosome
mkdir -p $output_dir

total_samples=137977
# Limited by open file descriptors.  Not sure how far to try and push it.
# Depends on OS and hardware specs
# 5 to 10 segments: Low CPU utilization on Peregrine at times
# 5 did not do well on Mortimer either
# Mortimer might do better with NFS over Infiniband
# < 5 segments: "Too many open files" error on Peregrine:
segments=8

# Integer division truncates, add 1 to round up segment size so the sum
# doesn't fall short of total_samples
segment_size=$(($total_samples / $segments + 1))

first=1
while [ $first -le $total_samples ]; do
    last=$(($first + $segment_size - 1))
    if [ $last -gt $total_samples ]; then
	last=$total_samples
    fi
    
    printf "Processing columns $first through $last...\n"
    bcftools view --min-ac 2 --exclude-types indels \
	../../phased/$bcf \
	| vcf-split --het-only $output_dir/chr$chromosome. $first $last
    
    first=$(($first + $segment_size))
done
