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
    printf "Usage: $0 sample-group (e.g. whi, bjm) MAF min-separation\n"
    exit 1
}


##########################################################################
#   Main
##########################################################################

if [ $# != 3 ]; then
    usage
fi
sample_group=$1
maf=$2
separation=$3

: ${SLURM_ARRAY_TASK_ID:=1}

my_vcf=$(find AD-VCFs-$sample_group -depth 1 -name '*-ad.vcf.xz' \
    | awk -v task=$SLURM_ARRAY_TASK_ID 'NR == task')
printf "Task $SLURM_ARRAY_TASK_ID processing $my_vcf on $(hostname)...\n"
base=$(basename $my_vcf)
outfile=AD-VCFs-$sample_group/MAF-$maf-${separation}nt/$base
xzcat $my_vcf | awk -v separation=$separation -f filter-sites.awk \
    | xz > $outfile
