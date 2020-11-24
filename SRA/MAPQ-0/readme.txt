
These ad2vcf runs filtered out unmapped reads using 

samtools view --input-fmt-option required_fields=0x208

and discarding reads with reported MAPQ=0.  Without the 0x01 bit set in
required_fields, samtools reports MAPQ=40 for mapped reads and MAPQ=0 for
unmapped reads.

ad2vcf was subsequently modified to unconditionally filter out unmapped reads
using the FLAG field BAM_FUNMAP bit, which should produce the same results.
https://github.com/samtools/samtools/issues/1329

In addition, ad2vcf now takes a second argument specifying the minimum MAPQ
value.  In addition to unmapped reads, ad2vcf will discard reads with a MAPQ
value strictly less than this value.
