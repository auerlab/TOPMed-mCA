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

printf "\n===================================================\n"

if [ $(cat $sample_file | wc -l) = 0 ]; then
    printf "$sample_file is empty.\n"
    exit
fi

mkdir -p $vcf_dir/Done
#export PATH=./local/bin:$PATH
which ad2vcf

acc_list=TOPMed_SraRunTable_20200729.txt.xz
for sample in $(awk '{ print $1 }' $sample_file); do
    vcf_input=$vcf_dir/combined.$sample.vcf.xz
    # Some samples in acc_list are not in the BCFs
    if [ ! -e $vcf_input ]; then
	printf "Missing VCF file: combined.$sample.vcf.xz\n"
    else
	# phs000920 and phs000921 opted out of providing data for out study
	# These should have been filtered out before upload, but check again
	study=$(xzcat $acc_list | awk -v sample=$sample '$3 == sample { print $2 }')
	if [ 0$study != 0phs000920 ] && [ 0$study != 0phs000921 ]; then
	    validated_vcf=$vcf_dir/Done/combined.$sample-ad.vcf.xz
	    if [ -e $validated_vcf ]; then
		printf "$sample already finished.\n"
	    else
		# Retry ad2vcf command until we verify that the CRAM is still
		# readable at the end and the VCF output is not corrupt.
		# Give up if ad2vcf returns EX_DATAERR, code 65, indicating
		# something wrong with the input.
		vcf_output=$vcf_dir/combined.$sample-ad.vcf.xz
		exit_status=0
		while [ ! -e $validated_vcf ] && [ $exit_status != 65 ]; do
		    mount_dir=$(pwd)/mount-$sample
		    mkdir -p $mount_dir
		    srr=$(xzcat $acc_list | awk -v sample=$sample '$3 == sample { print $4 }')
		    cram=$mount_dir/$srr/$sample.b38.irc.v1.cram
		
		    printf "Sample: $sample  SRR: $srr\n"
		    fusera mount -t Security/prj_13558_D25493.ngc -a $srr $mount_dir &
		    
		    # Verify that mount is complete before continuing
		    tries=0
		    while [ ! -e $cram ] && \
			  [ $tries -lt 10 ]; do
			printf "Waiting for fusera...\n"
			sleep 3
			tries=$((tries + 1))
		    done
		    
		    if [ tries = 10 ]; then
			printf "Giving up on $srr mount.\n"
		    else
			# Can't rely on exit status since samtools is unhappy
			# when ad2vcf closes the pipe.  Reading trailing junk
			# until EOF in ad2vcf would waste a lot of time.
			set +e
			time samtools view -@ 2 \
			    --input-fmt-option required_fields=0x218 \
			    $cram | ad2vcf $vcf_input 10
			exit_status=$?
			set -e
			
			# Check structure of last line and verify that fusera
			# mount is still readable.   Mounts sometimes go bad,
			# still showing files, but producing I/O errors
			# on read.
			if ! ./AWS-scripts/validate-vcf $vcf_output; then
			    printf "ad2vcf output corrupt.  Restarting job...\n"
			else
			    mv $vcf_output $vcf_dir/Done
			fi
			if [ -e $cram ]; then
			    fusera unmount $mount_dir
			fi
			rmdir $mount_dir || true
		    fi
		done
	    fi
	else
	    printf "Hey! Found $study in $sample_file.\n"
	    printf "This should have been filtered out before uploading!\n"
	fi
    fi
done
