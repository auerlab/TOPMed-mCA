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
#SBATCH --output=Logs/3d-filter-sites/filter-sites-%A_%a.out
#SBATCH --error=Logs/3d-filter-sites/filter-sites-%A_%a.err

usage()
{
    printf "Usage: $0 MAF min-separation\n"
    exit 1
}


##########################################################################
#   Main
##########################################################################

if [ $# != 2 ]; then
    usage
fi
maf=$1
separation=$2

: ${SLURM_ARRAY_TASK_ID:=1}

# These scripts were developed on a FreeBSD/SPCM cluster where all software is
# installed via FreeBSD ports into the default PATH.  If you need to load
# an environment module, activate a conda environent, etc. to gain access
# to software used below, do it here.

# Document software versions used for publication
uname -a
which bedtools
bedtools --version
pwd

my_sample=$(./select-sample.sh $SLURM_ARRAY_TASK_ID)
echo $my_sample
my_vcf=Data/2a-ad2vcf/combined.$my_sample-ad.vcf.xz

printf "Task $SLURM_ARRAY_TASK_ID processing $my_vcf on $(hostname)...\n"
printf "MAF: %s\nSeparation: %s\n" $maf $separation

filtered_dir=Data/3d-filter-sites/VCFs-MAF-$maf-${separation}nt-sv
mkdir -p $filtered_dir

base=$(basename $my_vcf)
outfile_sv=$filtered_dir/$base

# TODO: Filter sites that overlap DGV.GS.hg38.gff3
# Maybe add to filter-sites.awk?

printf "Filtering germline structural variants...\n"
germline=Data/3c-germline-vcf-combine/combined.$my_sample.bed

# Debug
#xzcat $my_vcf | head -2
#head -2 $germline
#xzcat $my_vcf \
#        | bedtools subtract -A -a stdin -b $germline \
#        | mawk -v separation=$separation -v maf=$maf -f 3d-filter-sites.awk
#exit

if [ -e $germline ]; then
    # Bedtools strips headers, so add it separately
    (xzcat $my_vcf | head | grep '^#'; xzcat $my_vcf \
	| bedtools subtract -A -a stdin -b $germline \
	| mawk -v separation=$separation -v maf=$maf -f 3d-filter-sites.awk ) \
	| xz -3 >> $outfile_sv
else
    printf "Note: No structural variant file for sample $sample.\n"
    # Bedtools strips headers, so add it separately
    # No point handling it differently here than above
    ( xzcat $my_vcf | head | grep '^#'; xzcat $my_vcf | grep -v '^#' \
	| mawk -v separation=$separation -v maf=$maf -f 3d-filter-sites.awk ) \
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
