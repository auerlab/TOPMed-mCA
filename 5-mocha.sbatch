#!/bin/sh -e

##########################################################################
#
#   Process filtered VCFs through MoCha
#
#   Do not submit this script directly.  Run 5-mocha.sh.
#       
#   History:
#   Date        Name        Modification
#   2021-12-08  Jason Wayne BaconBegin
##########################################################################

#SBATCH --mem=200
#SBATCH --output=Logs/5-mocha/mocha-%A_%a.out
#SBATCH --error=Logs/5-mocha/mocha-%A_%a.err

: ${SLURM_ARRAY_TASK_ID:=1}

# These scripts were developed on a FreeBSD cluster where all software is
# installed via FreeBSD ports into the default PATH.  If you need to load
# an environment module, activate a conda environent, etc. to gain access
# to software used below, do it here.

# Document software versions used for publication
uname -a
which bcftools
bcftools --version
pwd

## Set the location of the mocha plugins if they are not in the default path
# export BCFTOOLS_PLUGINS="/directory/containin/mochatools.so"

## Make sure you have this directory
## If you are on a networked filesystem, you may want to use local disk
tmpdir=/tmp

## Replace this with a real sample ID
my_sample=$(./select-sample.sh $SLURM_ARRAY_TASK_ID)

## input
vcf=combined.$my_sample-ad.vcf.xz

## temp output
bcf=$tmpdir/${vcf%.vcf.xz}.bcf
newbcf=$tmpdir/${vcf%.vcf.xz}.new.bcf

## out directory
outdir=Data/5-mocha

ref=Data/5-mocha/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna

echo "## prepare bcf input"
# Strip off non-standard 3rd digit ("other" count) in AD data.  This was
# added to maximize info extracted during expensive ad2vcf runs on AWS.
# Also strip depth from both format and sample data.
(cat MoCha/head.txt | sed -e "s|SAMPLE|$my_sample|g"; \
xzcat Data/3-filter/VCFs-MAF-0.05-1000nt-sv/$vcf \
    | grep -v '^#' | sed -E "s/,[[:digit:]]*:[[:digit:]]*$//g" \
    | sed -E "s/:DP//g" ) | bcftools view -i 'MIN(FMT/AD)>=5' \
    | bcftools norm --no-version -Ob -o $bcf -d none -f $ref
bcftools index -f $bcf

echo "## annotate gc content"
bcftools +mochatools $bcf -Ob -o $newbcf -- -t GC --fasta-ref $ref
bcftools index -f $newbcf

rm ${bcf}*

##output
otsv1=$outdir/$my_sample.stats.tsv
otsv2=$outdir/$my_sample.mocha.tsv

echo "## run mocha"
bcftools +mocha -g GRCh38 $newbcf -z $otsv1 -c $otsv2 \
    --LRR-weight 0.0 --bdev-LRR-BAF 6.0
cat $otsv2 | gzip -c > $otsv2.gz; rm $otsv2
cat $otsv1 | gzip -c > $otsv1.gz; rm $otsv1
