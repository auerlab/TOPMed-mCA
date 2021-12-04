#!/bin/sh -e

##########################################################################
#   Script description:
#       Run haplohseq on all .vcf.xz files in a directory
#   Arguments:
#       
#   Returns:
#       
#   History:
#   Date        Name        Modification
#   2020-09-13  Jason Bacon Begin
##########################################################################

usage()
{
    cat << EOM

Usage: $0 ad-vcf-dir event-prevalence event-megabases VCF-min-depth
	estimate-parameters(=y|n) [extra sbatch flags]

Example: $0 AD-VCFs-whi-MAPQ-0/MAF-0.05-1000nt-dgv 0.01 30 10 y [sbatch flags]

EOM
    exit 1
}


##########################################################################
#   Main
##########################################################################

if [ $# -lt 1 ]; then
    usage
fi
vcf_dir=$1
ep=$2
emb=$3
vmd=$4
est=$5
case $est in
y|n)
    ;;
*)
    usage
    ;;
esac
shift; shift; shift; shift; shift

ls $vcf_dir | grep '.*\.vcf\.xz' > $vcf_dir/VCF-list.txt
sample_count=$(cat $vcf_dir/VCF-list.txt | wc -l)
sample_count=$(printf "%d" $sample_count)   # Strip leading space

set -x
sbatch --array=1-$sample_count%160 "$@" 3h-haplohseq.sbatch \
    $vcf_dir $ep $emb $vmd $est
