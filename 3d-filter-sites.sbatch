#!/bin/sh -e

##########################################################################
#   Script description:
#       Filter VCFs for sites with MAF and min separation
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
    printf "Usage: $0 sample-group (e.g. whi, bjm) MAPQ-min MAF min-separation\n"
    exit 1
}


##########################################################################
#   Main
##########################################################################

if [ $# != 4 ]; then
    usage
fi
sample_group=$1
mapq_min=$2
maf=$3
separation=$4

: ${SLURM_ARRAY_TASK_ID:=1}

vcf_dir=AD-VCFs-$sample_group-MAPQ-$mapq_min
vcf_list=VCF-list.txt

cd $vcf_dir
my_vcf=$(awk -v task=$SLURM_ARRAY_TASK_ID 'NR == task' $vcf_list)

printf "Task $SLURM_ARRAY_TASK_ID processing $my_vcf on $(hostname)...\n"
base=$(basename $my_vcf)
outfile=MAF-$maf-${separation}nt/$base
xzcat $my_vcf | awk -v separation=$separation -f ../filter-sites.awk \
    | xz > $outfile
