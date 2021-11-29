##REF
ref=/home/yzhou3/ra_scratch90/ref.b38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna

id=NWD396907
tmpdir=/scratch/tmp123 
mkdir -p ${tmpdir}
##make sure you have this directory

##input
vcf=/home/yzhou3/ra_scratch90/mCA/Filtered-VCFs/combined.${id}-ad.vcf.xz

##temp output
bcf=${tmpdir}/combined.${id}-ad.bcf
newbcf=${tmpdir}/combined.${id}-ad.new.bcf

## out directory
outdir=./

echo "##prepare bcf input"
(cat head.txt | sed "s/SAMPLE/${id}/g"
xzcat ${vcf} | sed -E "s/,[[:digit:]]*:[[:digit:]]*$//g" | sed -E "s/:DP//g" ) | \
bcftools view -i 'MIN(FMT/AD)>=5' | bcftools norm --no-version -Ob -o ${bcf} -d none -f ${ref}
bcftools index -f ${bcf}

echo "##annotate gc content"
bcftools +/home/yzhou3/fast/tools/pub/mocha/mochatools.so ${bcf} -Ob -o ${newbcf} -- -t GC --fasta-ref ${ref}
bcftools index -f ${newbcf}

rm ${bcf}*

##output
out=${outdir}/combined.${id}-ad.out
otsv1=${out}.stats.tsv
otsv2=${out}.mocha.tsv

echo "## run mocha"
bcftools +/home/yzhou3/fast/tools/pub/mocha/mocha.so -g GRCh38 ${newbcf} -z ${otsv1} -c ${otsv2} --LRR-weight 0.0 --bdev-LRR-BAF 6.0
cat ${otsv2} | gzip -c > ${otsv2}.gz; rm ${otsv2}
cat ${otsv1} | gzip -c > ${otsv1}.gz; rm ${otsv1}

