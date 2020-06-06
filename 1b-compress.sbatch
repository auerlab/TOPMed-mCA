#!/bin/sh -e

##########################################################################
#   Script description:
#       Compress VCFs output by vcf-split.  This is safe to do
#       periodically while vcf-split is still running, as it only
#       compresses outputs of completed samples.
#       
#   History:
#   Date        Name        Modification
#   2020-02-24  Jason Bacon Begin
##########################################################################

#SBATCH --array=1-22
#SBATCH --mem=1g
#SBATCH --output=SLURM-outputs/compress-%A_%a.out
#SBATCH --error=SLURM-outputs/compress-%A_%a.err

# If running outside scheduler, SLURM_ARRAY_TASK_ID will not be set.
# Create a dummy task ID of 21 for single-sample testing on dev server.
: ${SLURM_ARRAY_TASK_ID:=21}

cd Split-vcfs
chr=$(printf "chr%02d" $SLURM_ARRAY_TASK_ID)
for file in $chr.*.vcf.done; do
    vcf=${file%.done}
    if [ -e $vcf ]; then
	printf "Compressing $vcf...\n"
	ls -l $vcf
	xz $vcf
	ls -l $vcf.xz
    fi
done
