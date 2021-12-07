#!/bin/sh -e

##########################################################################
#
#   Filter VCFs for sites with MAF and min separation
#
#   Do not submit this script directly.  Use 3d-filter-sites.sh.
#       
#   History:
#   Date        Name        Modification
#   2020-08-19  Jason Bacon Begin
##########################################################################

# --array is set by calling script based on size of vcf-list file
#SBATCH --mem=100
# 4 processes, but the xz bottleneck limits the total CPU to about 160%
# even if we give it 4 cores
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
vcf_list=VCF-list.txt   # In $vcf_dir

cd $vcf_dir
my_vcf=$(mawk -v task=$SLURM_ARRAY_TASK_ID 'NR == task' $vcf_list)
sample=$(echo $my_vcf | awk -F '[.-]' '{ print $2 }')
pwd

printf "Task $SLURM_ARRAY_TASK_ID processing $my_vcf on $(hostname)...\n"
printf "Sample group: %s\nMAPQ min: %s\nMAF: %s\nSeparation: %s\n" \
	$sample_group $mapq_min $maf $separation
base=$(basename $my_vcf)
outfile_sv=MAF-$maf-${separation}nt-sv/$base

# TODO: Filter sites that overlap DGV.GS.hg38.gff3
# Maybe add to filter-sites.awk?
# bedtools needs a basic header to identify the file type

printf "Filtering germline structural variants...\n"
germline=../79852-germline-structural-variants/Split-vcfs/combined.$sample.bed

# Assume samples with no structural variants should be tossed
pwd
if [ -e $germline ]; then
    (printf "##fileformat=VCFv4.2\n"; xzcat $my_vcf) \
	| bedtools subtract -A -a stdin -b $germline \
	| mawk -v separation=$separation -v maf=$maf -f ../3g-filter-sites.awk \
	| xz -3 > $outfile_sv
else
    printf "Note: No structural variant file for sample $sample.\n"
    printf "Applying MAF and distance filters anyway.\n"
    xzcat $my_vcf \
	| mawk -v separation=$separation -v maf=$maf -f ../3g-filter-sites.awk \
	| xz -3 > $outfile_sv
fi
    
# Previous we filtered out sites in the DGV (database of genomic variants)
# This has been replaced by the dbGaP germline structural variants above
# printf "Filtering with DGV...\n"
# (printf "##fileformat=VCFv4.2\n"; xzcat $my_vcf) \
#     | bedtools subtract -A -a stdin -b ../DGV.GS.hg38.gff3 \
#     | mawk -v separation=$separation -v maf=$maf -f ../filter-sites.awk \
#     | xz > $outfile_dgv

# Only for comparison to see the effects of DGV filtering
# outfile=MAF-$maf-${separation}nt/$base
# printf "Filtering without DGV...\n"
# (printf "##fileformat=VCFv4.2\n"; xzcat $my_vcf) \
#     | mawk -v separation=$separation -v maf=$maf -f ../filter-sites.awk \
#     | xz > $outfile
