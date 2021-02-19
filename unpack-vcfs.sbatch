#!/bin/sh -e

##########################################################################
#   Script description:
#       Unpack V
#
#       Don't run this directly: Use ./unpack-vcfs sample-group MAPQ-min
#       
#   History:
#   Date        Name        Modification
#   2021-02-08  Jason Bacon Begin
##########################################################################

#SBATCH --mem=100
#SBATCH --output=SLURM-outputs/unpack-vcfs-%A_%a.out
#SBATCH --error=SLURM-outputs/unpack-vcfs-%A_%a.err

usage()
{
    printf "Usage: $0 sample-group (e.g. whi, bjm) MAPQ-min\n"
    exit 1
}


##########################################################################
#   Main
##########################################################################

if [ $# != 2 ]; then
    usage
fi
sample_group=$1
mapq_min=$2

: ${SLURM_ARRAY_TASK_ID:=1}

vcf_dir=AD-VCFs-$sample_group-MAPQ-$mapq_min
vcf_list=VCF-list.txt

cd $vcf_dir
my_vcf=$(mawk -v task=$SLURM_ARRAY_TASK_ID 'NR == task' $vcf_list)

printf "Task $SLURM_ARRAY_TASK_ID uncompressing $my_vcf on $(hostname)...\n"
base=$(basename ${my_vcf%.xz})
xzcat $my_vcf > Uncompressed/$base
