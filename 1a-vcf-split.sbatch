#!/bin/sh -e

##########################################################################
#   Script description:
#
#   Split a multisample BCF file into single-sample VCFs.
#
#   This is best run on a filesystem that support compression, such as
#   ZFS.  Piping thousands of output streams through xz at the same time
#   is not feasible since it requires an xz process for each stream.
#
#   bcftools notes:
#
#   --min-ac + --genotype about doubles run time
#   --min-ax + --samples increases run time by order of magnitude
#
#   Filtering out calls with no het sites via bcftools is useless with 137k
#   samples per call.  Every call is likely to have het sites in some samples.
#   Hence, het filtering is performed by vcf-split on each output stream.
#
#   vcftools is much slower than bcftools
#
#   vcf-split is limited by the number of open files your filesystem can
#   write at once.  Tens of thousands are usually feasible on a high-end
#   server when filtering for het sites only, which greatly reduces output.
#   Keep in mind that open files add up with parallel jobs accessing the same
#   file server.
#
#   History:
#   Date        Name        Modification
#   2019-12-08  Jason Bacon Begin
##########################################################################

# 1 multi-sample file for each of 23 chronmosomes.  Limit to 10 jobs
# (10k open files) at a time to avoid overloading the file server.
#SBATCH --array=1-23%10
# 1 core for bcftools, 1 for vcf-split
#SBATCH --cpus-per-task=2
#SBATCH --mem=300
#SBATCH --output=Logs/1-vcf-split/vcf-split-%A_%a.out
#SBATCH --error=Logs/1-vcf-split/vcf-split-%A_%a.err

# If running outside scheduler, SLURM_ARRAY_TASK_ID will not be set.
# Create a dummy task ID of 21 for single-sample testing on dev server.
# 21 is the smallest of the chromosomes for which errors were reported
: ${SLURM_ARRAY_TASK_ID:=21}
: ${SLURM_JOB_ID:=1}

# Document software versions used for publication
if [ $SLURM_ARRAY_TASK_ID = 1 ]; then
    uname -a > Logs/1-vcf-split/os-version-vcf-split-$SLURM_JOB_ID.txt 2>&1
    bcftools --version > Logs/1-vcf-split/bcftools-version-$SLURM_JOB_ID.txt
    vcf-split --version > Logs/1-vcf-split/vcf-split-version-$SLURM_JOB_ID.txt 2>&1
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
# Limit total open files on file server to 10k.
max_samples=1000
if [ $(cat $sample_id_file | wc -l) -gt $max_samples ]; then
    cat << EOM
    
$sample_id_file contains too many samples.  Please limit to $max_samples
to prevent overloading the disk.

EOM
    exit 1
fi

# Limit $last_sample_col - $first_sample_col + 1 to $max_samples if
# not using --sample-id-file
first_sample_col=1
last_sample_col=137977
bcftools view --min-ac 2 --exclude-types indels Raw-bcfs/$bcf \
    | vcf-split --het-only --sample-id-file samples.txt \
    --fields chrom,pos,ref,alt,format \
    $output_dir/chr$two_digit_chrom. $first_sample_col $last_sample_col
