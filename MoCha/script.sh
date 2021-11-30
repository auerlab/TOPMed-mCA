#!/bin/sh -ex

##########################################################################
#   Script description:
#       Example MoCha script
#
#       For detailed information, see https://github.com/freeseek/mocha
#       
#   History:
#   Date        Name        Modification
#   2021-11-29  Ying Zhou   Begin
#   2021-11-29  Jason Bacon Generalize for portability
##########################################################################

##########################################################################
#   Main
##########################################################################

## REF
ref=GCA_000001405.15_GRCh38_no_alt_analysis_set.fna
site=https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/001/405/GCA_000001405.15_GRCh38/seqs_for_alignment_pipelines.ucsc_ids
if [ ! -e $ref ]; then
    curl -C - -O $site/$ref.gz
    gunzip $ref.gz
fi

## Set the location of the mocha plugins if they are not in the default path
# export BCFTOOLS_PLUGINS="/directory/containin/mochatools.so"

## Make sure you have this directory
## If you are on a networked filesystem, you make want to use local disk
tmpdir=.

## Replace this with a real sample ID
id=NWD000000

## input
vcf=sample.${id}-ad.vcf.xz

## temp output
bcf=${tmpdir}/${vcf%.vcf.xz}.bcf
newbcf=${tmpdir}/${vcf%.vcf.xz}.new.bcf

## out directory
outdir=.

echo "## prepare bcf input"
(cat head.txt | sed "s/SAMPLE/${id}/g"
xzcat ${vcf} | sed -E "s/,[[:digit:]]*:[[:digit:]]*$//g" | sed -E "s/:DP//g" ) | \
bcftools view -i 'MIN(FMT/AD)>=5' \
    | bcftools norm --no-version -Ob -o ${bcf} -d none -f ${ref}
bcftools index -f ${bcf}

echo "## annotate gc content"
bcftools +mochatools ${bcf} -Ob -o ${newbcf} -- -t GC --fasta-ref ${ref}
bcftools index -f ${newbcf}

rm ${bcf}*

##output
out=${outdir}/${vcf%.vcf.xz}.out
otsv1=${out}.stats.tsv
otsv2=${out}.mocha.tsv

echo "## run mocha"
bcftools +mocha -g GRCh38 ${newbcf} -z ${otsv1} -c ${otsv2} \
    --LRR-weight 0.0 --bdev-LRR-BAF 6.0
cat ${otsv2} | gzip -c > ${otsv2}.gz; rm ${otsv2}
cat ${otsv1} | gzip -c > ${otsv1}.gz; rm ${otsv1}
