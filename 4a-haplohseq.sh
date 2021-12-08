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

Usage: $0 event-prevalence event-megabases VCF-min-depth \\
    estimate-parameters(=y|n) [extra sbatch flags]

Example: $0 0.01 30 10 y [sbatch flags]

EOM
    exit 1
}


##########################################################################
#   Main
##########################################################################

if [ $# != 4 ]; then
    usage
fi
ep=$1
emb=$2
vmd=$3
est=$4
case $est in
y|n)
    ;;
*)
    usage
    ;;
esac
shift; shift; shift; shift

sample_count=$(cat Data/1-vcf-split/sample-list-all | wc -l)
sample_count=$(echo $sample_count)   # Strip leading space
printf "Running haplohseq on %u samples...\n" $sample_count

set -x
sbatch --array=1-$sample_count%100 "$@" 4a-haplohseq.sbatch $ep $emb $vmd $est
