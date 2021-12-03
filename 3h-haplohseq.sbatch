#!/bin/sh -e

# Peregrine: Getting stale NFS handles on xzcat | sed with %24 or more
# Probably timeouts from too much NFS load for the 1G network
# Using local /tmp for uncompressed files eliminated the issue
#SBATCH --mem=1g
#SBATCH --output=SLURM-outputs/haplohseq-%A_%a.out
#SBATCH --error=SLURM-outputs/haplohseq-%A_%a.err

##########################################################################
#   Script description:
#       Run haplohseq on all .vcf.xz files in a directory
#       Don't run this directly:
#       Use
#           ./3d-haplohseq $dir
#
#   History:
#   Date        Name        Modification
#   2020-09-13  Jason Bacon Begin
##########################################################################

usage()
{
    cat << EOM

Usage: $0 ad-vcf-dir event-prevalence event-megabases VCF-min-depth \
	estimate-parameters(=y|n)

EOM
    exit 1
}


##########################################################################
#   Main
##########################################################################

if [ $# != 5 ]; then
    usage
fi
vcf_dir=$1
ep=$2
emb=$3
vmd=$4
est=$5
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
: ${SLURM_JOB_ID:=1}

cd $vcf_dir

# Generate a static list VCF-list.txt in the calling script and use it here.
my_vcf=$(awk -v i=$SLURM_ARRAY_TASK_ID 'NR == i { print $0 }' VCF-list.txt)

# Use local disk for uncompressed files to offload NFS
uncompressed=/tmp/${my_vcf%.xz}
my_vcf_prefix=`echo $my_vcf | cut -d - -f 1`
output_dir=Haplo-ep-$ep-emb-$emb-vmd-$vmd-est-$est
sample=${my_vcf_prefix##*.}
hostname
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

# ../../../local/bin version should be built with portable optimizations
# On FreeBSD, can also use ports version optimized for each compute node
# export PATH=../../../../local/bin:$PATH
which vcf2hap haplohseq

printf "Uncompressing...\n"
# Peregrine: xzcat is causing intermittent failures in vcf2hap
# Examining the files later shows they are all OK
# The problem only occurs shortly after xzcat completes
# xzcat < $filename > $uncompressed
# Same issue does not occur when using unxz
# Buffering issue when using redirection?  Does stdout pass through SLURM?
# Removing $uncompressed beforehand fixes the issue
rm -f $uncompressed
xzcat < $my_vcf | sed -E 's|,[0-9]+:|:|' > $uncompressed
sync

# Generate hap file from VCF
printf "\nSTEP 1: GENERATING HAPLOTYPE FILES...\n"
printf "Generating .hap file...\n"
vcf2hap $sample < $uncompressed > $my_vcf_prefix-ad.hap
sync

# Identify allelic imbalance (AI) given a tumor
# exome VCF file generated using the UnifiedGenotyper
# of the GATK. This involves the following 3 steps.

# Our files are already phased
# printf "STEP 1: PHASING 1KG HET SITES ...\n"
# python ../scripts/simple_phaser.py \
#  --ldmap ../ldmap/hg19.exome.ldmap \
#  --vcf example_input/tumor_exome.vcf \
#  -o example_output/tumor_exome

# Paul Auer 2020-12-01:
#   --event_mb 50   (default is 20)
#   --est_normal_emissions
#   --est_aberrant_emissions

mkdir -p $output_dir
if [ -e $output_dir/$my_vcf_prefix.events.dat ]; then
    printf "haplohseq --event_mb 30 already done.\n"
else
    time haplohseq \
	--vcf $uncompressed \
	--phased $my_vcf_prefix-ad.hap \
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

# Should not be needed
exit 0
if [ -e $output_dir/${my_vcf}_haplohseq.png ]; then
    printf "Plotting already done.\n"
else
    printf "\nSTEP 3: PLOTTING HAPLOHSEQ GENOMIC AI PROFILE ...\n"
    time Rscript /usr/local/share/examples/haplohseq/scripts/haplohseq_plot.R \
	--file $output_dir/$my_vcf_prefix.posterior.dat \
	--out $output_dir \
	--prefix ${my_vcf}_haplohseq
fi
