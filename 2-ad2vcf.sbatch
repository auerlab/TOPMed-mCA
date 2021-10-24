#!/bin/csh -ef

#SBATCH --array=1-22
#SBATCH --cpus-per-task=3
#SBATCH --mem=1g
#SBATCH --output=SLURM-outputs/ad2vcf-%A_%a.out
#SBATCH --error=SLURM-outputs/ad2vcf-%A_%a.err

cat << EOM

This script was not used in the analysis, since the necessary CRAM files
were not available on a cluster.

The ad2vcf step was run on AWS using the scripts in the SRA directory.

EOM
exit

# Cannot download all samples, so just use a few
# Create array of filenames (1-based)
# Make sure --array above matches the # of files
set samples=(`ls ../../SRR6990379/*.cram | cut -d / -f 4 | cut -d . -f 1`)

# Alternative run for testing samples that failed for Josh
# set samples=(`cat buffer-overflow-samples.txt`)

if ( -e /sharedapps/pkg-2019Q2/bin/samtools ) then
    source /etc/csh.cshrc
    module load /sharedapps/pkg-2019Q2/etc/modulefiles/pkgsrc/2019Q2
endif

set vcf_dir = Split-vcfs
cd $vcf_dir

# ../../../local/bin version should be built with portable optimizations
# On FreeBSD, can also use ports version optimized for each compute node
setenv PATH ../../../local/bin:${PATH}
which ad2vcf

printf "ad2vcf: processing $samples[$SLURM_ARRAY_TASK_ID]...\n"
samtools view -@ 2 --input-fmt-option required_fields=0x208 \
	../../../SRR6990379/$samples[$SLURM_ARRAY_TASK_ID].b38.irc.v1.cram \
    | ad2vcf combined.$samples[$SLURM_ARRAY_TASK_ID].vcf.xz
echo $status
