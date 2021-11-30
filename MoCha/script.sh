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

##REF
ref=GCA_000001405.15_GRCh38_no_alt_analysis_set.fna
if [ ! -e $ref ]; then
    curl -C - -O ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/001/405/GCA_000001405.15_GRCh38/seqs_for_alignment_pipelines.ucsc_ids/$ref.gz
    gunzip $ref.gz
fi

id=NWD396907
tmpdir=.
##make sure you have this directory

##input
vcf=combined.${id}-ad.vcf.xz

##temp output
bcf=${tmpdir}/combined.${id}-ad.bcf
newbcf=${tmpdir}/combined.${id}-ad.new.bcf

## out directory
outdir=.

echo "##prepare bcf input"
(cat head.txt | sed "s/SAMPLE/${id}/g"
xzcat ${vcf} | sed -E "s/,[[:digit:]]*:[[:digit:]]*$//g" | sed -E "s/:DP//g" ) | \
bcftools view -i 'MIN(FMT/AD)>=5' | bcftools norm --no-version -Ob -o ${bcf} -d none -f ${ref}
bcftools index -f ${bcf}

# export BCFTOOLS_PLUGINS="/directory/containin/mochatools.so"
echo "##annotate gc content"
bcftools +mochatools ${bcf} -Ob -o ${newbcf} -- -t GC --fasta-ref ${ref}
bcftools index -f ${newbcf}

rm ${bcf}*

##output
out=${outdir}/combined.${id}-ad.out
otsv1=${out}.stats.tsv
otsv2=${out}.mocha.tsv

echo "## run mocha"
bcftools +mocha -g GRCh38 ${newbcf} -z ${otsv1} -c ${otsv2} --LRR-weight 0.0 --bdev-LRR-BAF 6.0
cat ${otsv2} | gzip -c > ${otsv2}.gz; rm ${otsv2}
cat ${otsv1} | gzip -c > ${otsv1}.gz; rm ${otsv1}

