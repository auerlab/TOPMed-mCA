#!/bin/sh -e

##########################################################################
#
#   Split a multisample BCF file into single-sample VCFs.
#
#   This is best run on a filesystem that supports compression, such as
#   ZFS.  Piping the thousands of output streams of a single vcf-split
#   process through xz at the same time is not feasible since it would
#   require an xz process for each stream.
#   Compression of all output files is performed after by 1b-compress.*.
#
#   bcftools is much faster than vcftools
#
#   bcftools notes:
#
#   --min-ac + --genotype about doubles run time
#   --min-ax + --samples increases run time by order of magnitude
#
#   Filtering out calls with no het sites via bcftools is useless here
#   since it discards the call if *any* sample has a het site.
#   Hence, het filtering is performed by vcf-split on each output stream.
#
#   vcf-split is limited by the number of open files your filesystem can
#   write at once.  Tens of thousands are usually feasible on a high-end
#   server when filtering for het sites only, which greatly reduces output.
#   If outputting all calls, limit the number of samples to a few thousand.
#   Keep in mind that open files add up with parallel jobs accessing the same
#   file server.
#
#   All necessary tools are assumed to be in PATH.  If this is not
#   the case, add whatever code is needed here to gain access.
#   (Adding such code to your .bashrc or other startup script is
#   generally a bad idea since it's too complicated to support
#   every program with one environment.)
#
#   History:
#   Date        Name        Modification
#   2019-12-08  Jason Bacon Begin
##########################################################################

# 1 multi-sample file for each of 23 chromosomes.  Limit to 10 active jobs
# (10 * $max_samples open files) to avoid overloading the file server.
##SBATCH --array=1-23%10
#SBATCH --array=1-23
# 1 core for bcftools, 1 for vcf-split
#SBATCH --cpus-per-task=2
#SBATCH --mem=300
#SBATCH --output=Logs/1a-vcf-split/vcf-split-%A_%a.out
#SBATCH --error=Logs/1a-vcf-split/vcf-split-%A_%a.err

# If running outside scheduler, SLURM_ARRAY_TASK_ID will not be set.
# Create a dummy task ID of 21 for single-sample testing on dev server.
# 21 is the smallest of the chromosomes for which errors were reported
: ${SLURM_ARRAY_TASK_ID:=21}

# These scripts were developed on a FreeBSD cluster where all software is
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
pwd

# Organize by chromosome to reduce # of files in each dir
output_dir=1a-vcf-split/chr$two_digit_chrom
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
