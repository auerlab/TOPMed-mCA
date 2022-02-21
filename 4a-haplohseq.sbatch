#!/bin/sh -e

##########################################################################
#
#   Run haplohseq on all .vcf.xz files in a directory
#   Do not submit this script directly:
#   Use ./3d-haplohseq.sh
#
#   History:
#   Date        Name        Modification
#   2020-09-13  Jason Bacon Begin
##########################################################################

#SBATCH --mem=1g
#SBATCH --output=Logs/4-haplohseq/haplohseq-%A_%a.out
#SBATCH --error=Logs/4-haplohseq/haplohseq-%A_%a.err

usage()
{
    cat << EOM

Usage: $0 event-prevalence event-megabases VCF-min-depth \
	estimate-parameters(=y|n)

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
y)
    est_flags='--est_normal_emissions --est_aberrant_emissions'
    ;;
n)
    est_flags=''
    ;;
*)
    usage
    ;;
esac

# Dummy value for testing outside SLURM env
: ${SLURM_ARRAY_TASK_ID:=1}

# These scripts were developed on a FreeBSD/SPCM cluster where all software is
# installed via FreeBSD ports into the default PATH.  If you need to load
# an environment module, activate a conda environent, etc. to gain access
# to software used below, do it here.

# Document software versions used for publication
uname -a
which vcf2hap
which haplohseq
vcf2hap --version
haplohseq --version
pwd

vcf_dir=Data/3-filter/VCFs-MAF-0.05-1000nt-sv

# Generate a static list VCF-list.txt in the calling script and use it here.
my_sample=$(./select-sample.sh $SLURM_ARRAY_TASK_ID)
my_vcf=combined.$my_sample-ad.vcf.xz
xzcat $vcf_dir/$my_vcf | head

# haplohseq requires uncompressed VCF input.
# Use local disk for uncompressed files to offload NFS.
uncompressed=/tmp/${my_vcf%.xz}
my_vcf_prefix=`echo $my_vcf | cut -d - -f 1`
output_dir=Data/4-haplohseq/EP-$ep-EMB-$emb-VMD-$vmd-Est-$est
sample=${my_vcf_prefix##*.}
printf "TASK ID:        $SLURM_ARRAY_TASK_ID\n"
printf "VCF:            $my_vcf\n"
printf "Uncompressed:   $uncompressed\n"
printf "Prefix:         $my_vcf_prefix\n"
printf "Sample:         $sample\n"
printf "Output dir:     $output_dir\n"
printf "VCF dir:        $vcf_dir\n"
printf "Event prev:     $ep\n"
printf "Min MB:         $emb\n"
printf "VCF min depth:  $vmd\n"
printf "Estimate parms: $est\n"


printf "Uncompressing...\n"
rm -f $uncompressed
xzcat < $vcf_dir/$my_vcf | sed -E 's|,[0-9]+:|:|' > $uncompressed
sync

# Generate hap file from VCF
printf "\nSTEP 1: GENERATING HAPLOTYPE FILES...\n"
printf "Generating .hap file...\n"

mkdir -p $output_dir
vcf2hap $sample < $uncompressed > $output_dir/$my_vcf_prefix-ad.hap

########################################################################
# Our files are already phased.  If yours are not, run simple_phaser.py
# or similar tool.
#
# python ../scripts/simple_phaser.py \
#  --ldmap ../ldmap/hg19.exome.ldmap \
#  --vcf example_input/tumor_exome.vcf \
#  -o example_output/tumor_exome

if [ -e $output_dir/$my_vcf_prefix.events.dat ]; then
    printf "haplohseq --event_mb 30 already done.\n"
else
    time haplohseq \
	--vcf $uncompressed \
	--phased $output_dir/$my_vcf_prefix-ad.hap \
	--event_prevalence $ep \
	--event_mb $emb \
	--vcf_min_depth $vmd \
	$est_flags \
	-d $output_dir \
	-p $my_vcf_prefix
fi

# Save space
rm -f $uncompressed $my_vcf_prefix-ad.hap
# Usually want to do this, but occasionally need to look at posterior files
# rm -f $output_dir_emb30/$my_vcf_prefix.posterior.dat
