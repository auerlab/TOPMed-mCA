#!/bin/sh -e

##########################################################################
#   Script description:
#       Filter VCFs for sites with MAF >= 0.01
#       
#   History:
#   Date        Name        Modification
#   2020-08-19  Jason Bacon Begin
##########################################################################

#SBATCH --array=1-2765%50
#SBATCH --mem=100
#SBATCH --ntasks=2
#SBATCH --output=SLURM-outputs/filter-sites-%A_%a.out
#SBATCH --error=SLURM-outputs/filter-sites-%A_%a.err

: ${SLURM_ARRAY_TASK_ID:=1}

my_vcf=$(ls ../Split-vcfs/Combined+AD/combined.*-ad.vcf.xz | \
    awk -v task=$SLURM_ARRAY_TASK_ID 'NR == task')
printf "Processing $my_vcf...\n"
base=$(basename $my_vcf)
outfile=Filtered-vcfs/${base%.vcf.xz}-maf-0.01.vcf.xz
xzcat $my_vcf | awk -f filter-sites.awk | xz > $outfile
