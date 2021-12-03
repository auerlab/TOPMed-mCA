#!/bin/sh -e

##########################################################################
#   Script description:
#       Uncompress a few xzipped VCFs at a time
#       
#   History:
#   Date        Name        Modification
#   2021-03-06  Jason Bacon Begin
##########################################################################

#SBATCH --mem=200
#SBATCH --output=SLURM-outputs/uncompress-%A_%a.out
#SBATCH --error=SLURM-outputs/uncompress-%A_%a.err

usage()
{
    printf "Usage: $0 sample-list\n"
    exit 1
}


##########################################################################
#   Main
##########################################################################

if [ $# != 2 ]; then
    usage
fi
sample_list=$1
maf=$2

: ${SLURM_ARRAY_TASK_ID:=10}
: ${SLURM_JOB_ID:=1}

cd AD-VCFs-whi-MAPQ-0/MAF-$maf
my_sample=$(awk -v my_index=$SLURM_ARRAY_TASK_ID 'NR == my_index { print $0 }' $sample_list)
printf "Uncompressing $my_sample on $(hostname)...\n"
xzcat combined.$my_sample-ad.vcf.xz > Uncompressed/combined.$my_sample-ad.vcf
