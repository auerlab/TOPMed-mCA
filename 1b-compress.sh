#!/bin/sh -e

##########################################################################
#
#   Launch a batch script to compress vcf-split outputs in parallel.
#   May need to increase SLURM MaxJobCount and MaxArraySize
#   Also see SLURM high throughput tuning guide to avoid scheduler
#   timeouts.
#
#   This script can be run in parallel with vcf-split. The vcf-split
#   script creates a .vcf.done file indicating when a VCF is
#   complete, so that this script will know which VCFs are ready
#   to compress.
#
#   All necessary tools are assumed to be in PATH.  If this is not
#   the case, add whatever code is needed here to gain access.
#   (Adding such code to your .bashrc or other startup script is
#   generally a bad idea since it's too complicated to support
#   every program with one environment.)
#
#   History:
#   Date        Name        Modification
#   2020-06-16  Jason Bacon Begin
##########################################################################

usage()
{
    printf "Usage: $0 max-parallel-jobs\n"
    exit 1
}


##########################################################################
#   Main
##########################################################################

if [ $# != 1 ]; then
    usage
fi
max_jobs=$1

# Generate VCF file list from which jobs will extract their filename by
# position using $SLURM_ARRAY_TASK_ID
cd Data/1b-compress
mv ../1a-vcf-split/* . || true
vcf_list=vcf-list-all

# Be sure not to clobber the files being used by current jobs!
# rm $vcf_list
if [ -e $vcf_list ]; then
    cat << EOM

$vcf_list already exists.  Is a job already running?

Wait for the job to finish and remove $vcf_list to start again.

EOM
    exit 1
fi

# Completed vcf-split outputs are accompanied by a .vcf.done file
# Search for .done files, but strip the .done from the name so the
# list contains .vcf files
printf "Finding VCFs...\n"
printf "$(find chr* -name '*.vcf.done' | wc -l) done splitting\n"
printf "$(find chr* -name '*.vcf' | wc -l) total VCFs\n"
find chr* -name '*.vcf.done' | cut -d . -f 1-3 > $vcf_list

tj=$(cat $vcf_list | wc -l)
total_jobs=$(echo $tj)   # Get rid of leading whitespace from wc
printf "Total files to compress = $total_jobs\n"

# Split the find output into small chunks so each job has a quick awk search
# It takes a few seconds to search a file with 1 million lines whereas
# 1,000 lines is instantaneous.  This cut the compression of 1 million files
# from 25 hours to 12.
max_lines=1000
printf "Splitting file list...\n"
split -l $max_lines -a 4 -d $vcf_list vcf-list-
wc -l vcf-list-[0-9]*

cd ../..
read -p 'Submit? y/[n] ' submit
if [ 0$submit = 0y ]; then
    set -x
    sbatch --array=1-${total_jobs}%$max_jobs 1b-compress.sbatch
fi
