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
    printf "Usage: $0 sample-file VCF-dir\n"
    exit 1
}


##########################################################################
#   Main
##########################################################################

if [ $# != 2 ]; then
    usage
fi
sample_file=$1
vcf_dir=$2

mkdir -p $vcf_dir/Done

#export PATH=./local/bin:$PATH
which ad2vcf

acc_list=TOPMed_SraRunTable_20190628.txt
for sample in $(awk '{ print $1 }' $sample_file); do
    study=$(awk -v sample=$sample '$3 == sample { print $2 }' $acc_list)
    # Studies should have been filtered out before upload, but check again
    if [ $study != phs000920 ] && [ $study != phs000921 ]; then
	if [ -e $vcf_dir/Done/combined.$sample-ad.vcf.xz ]; then
	    printf "$sample already finished.\n"
	else
	    mount_dir=$(pwd)/mount-$sample
	    mkdir -p $mount_dir
	
	    srr=$(awk -v sample=$sample '$3 == sample { print $4 }' $acc_list)
	    printf "\n===================================================\n"
	    printf "Sample: $sample  SRR: $srr\n"
	    fusera mount -t Security/prj_13558_D25493.ngc -a $srr $mount_dir &
	    while [ ! -e $mount_dir/$srr/$sample.b38.irc.v1.cram ]; do
		printf "Waiting for fusera...\n"
		sleep 1
	    done
	    ls $mount_dir/$srr
	    
	    time samtools view -@ 2 --input-fmt-option required_fields=0x208 \
		$mount_dir/$srr/$sample.b38.irc.v1.cram \
		| ad2vcf $vcf_dir/combined.$sample.vcf.xz
	    mv $vcf_dir/combined.$sample-ad.vcf.xz $vcf_dir/Done
	    
	    fusera unmount $mount_dir
	    rmdir $mount_dir
	fi
    else
	printf "Hey! Found $study in $sample_file.\n"
	printf "This should have been filtered out before uploading!\n"
    fi
done
