#!/bin/sh -e

##########################################################################
#   Script description:
#       Process samples through ad2vcf
#       
#   History:
#   Date        Name        Modification
#   2020-07-27              Begin
##########################################################################

usage()
{
    printf "Usage: $0 sample-file\n"
    exit 1
}


##########################################################################
#   Main
##########################################################################

if [ $# != 1 ]; then
    usage
fi
sample_file=$1

#export PATH=./local/bin:$PATH
which ad2vcf

for sample in $(cat $sample_file); do
    mount_dir=$(pwd)/mount-$sample
    mkdir -p $mount_dir

    srr=$(awk -v sample=$sample '$3 == sample { print $4 }' TOPMed_SraRunTable_20190628.txt)
    printf "Sample: $sample  SRR: $srr\n"
    fusera mount -t Security/prj_13558_D25493.ngc -a $srr $mount_dir &
    while [ ! -e $mount_dir/$srr/$sample.b38.irc.v1.cram ]; do
	printf "Waiting for fusera...\n"
	sleep 1
    done
    ls $mount_dir/$srr
    
    time samtools view -@ 2 --input-fmt-option required_fields=0x208 \
	$mount_dir/$srr/$sample.b38.irc.v1.cram \
	| ad2vcf combined.$sample.vcf.xz
    
    fusera unmount $mount_dir
    rmdir $mount_dir
done
