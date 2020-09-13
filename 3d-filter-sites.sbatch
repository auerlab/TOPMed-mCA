#!/bin/sh -e

##########################################################################
#   Script description:
#       Filter VCFs for sites with MAF >= 0.01 and separated by 1000kb
#       or more.
#
#       Don't run this directly: Use
#           ./3d-filter-sites sample-group
#       
#   History:
#   Date        Name        Modification
#   2020-08-19  Jason Bacon Begin
##########################################################################

#SBATCH --mem=100
#SBATCH --ntasks=2
#SBATCH --output=SLURM-outputs/filter-sites-%A_%a.out
#SBATCH --error=SLURM-outputs/filter-sites-%A_%a.err

usage()
{
    printf "Usage: $0 sample-group (e.g. whi, bjm)\n"
    exit 1
}


##########################################################################
#   Main
##########################################################################

if [ $# != 1 ]; then
    usage
fi
sample_group=$1

: ${SLURM_ARRAY_TASK_ID:=1}

my_vcf=$(ls AD-VCFs-$sample_group/combined.*-ad.vcf.xz | \
    awk -v task=$SLURM_ARRAY_TASK_ID 'NR == task')
printf "Processing $my_vcf...\n"
base=$(basename $my_vcf)
mkdir -p AD-VCFs-$sample_group/Filtered
outfile=AD-VCFs-$sample_group/Filtered/${base%.vcf.xz}-maf-0.01.vcf.xz
xzcat $my_vcf | awk -f filter-sites.awk | xz > $outfile
