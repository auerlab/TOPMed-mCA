#!/bin/sh -e

##########################################################################
#   Script description:
#       Filter VCFs for sites with MAF and min separation
#
#       Don't run this directly: Use
#           ./4a-matrix-filter-sites sample-group
#       
#   History:
#   Date        Name        Modification
#   2020-08-19  Jason Bacon Begin
##########################################################################

#SBATCH --mem=100
# 4 processes, but the xz bottleneck limits the total CPU to about 160%
# even if we give it 4 cores
#SBATCH --ntasks=2
#SBATCH --output=SLURM-outputs/matrix-filter-sites-%A_%a.out
#SBATCH --error=SLURM-outputs/matrix-filter-sites-%A_%a.err

usage()
{
    printf "Usage: $0 sample-group (e.g. whi, bjm) MAPQ-min MAF min-separation\n"
    exit 1
}


##########################################################################
#   Main
##########################################################################

if [ $# != 3 ]; then
    usage
fi
sample_group=$1
mapq_min=$2
maf=$3

: ${SLURM_ARRAY_TASK_ID:=1}

vcf_dir=AD-VCFs-$sample_group-MAPQ-$mapq_min
vcf_list=VCF-list.txt

cd $vcf_dir
my_vcf=$(mawk -v task=$SLURM_ARRAY_TASK_ID 'NR == task' $vcf_list)
sample=$(echo $my_vcf | awk -F '[.-]' '{ print $2 }')

printf "Task $SLURM_ARRAY_TASK_ID processing $my_vcf on $(hostname)...\n"
base=$(basename $my_vcf)
outfile=MAF-$maf/$base

# These scripts were developed on a FreeBSD cluster where all software is
# installed via FreeBSD ports into the default PATH.  If you need to load
# an environment module, activate a conda environent, etc. to gain access
# to software used below, do it here.

# Document software versions used for publication
uname -a
which xzcat
which mawk
pwd

# TODO: Filter sites that overlap DGV.GS.hg38.gff3
# Maybe add to filter-sites.awk?
# bedtools needs a basic header to identify the file type

(printf "##fileformat=VCFv4.2\n"; xzcat $my_vcf) \
    | mawk -v separation=0 -v maf=$maf -f ../3g-filter-sites.awk \
    | xz -3 > $outfile
