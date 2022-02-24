#!/bin/sh -e

##########################################################################
#
#   Launch a batch job to combine vcf-split outputs in parallel.
#   May need to increase SLURM MaxJobCount and MaxArraySize
#   Also see SLURM high throughput tuning guide to avoid scheduler
#   timeouts
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

cd Data/1c-combine
pwd

sample_list=sample-list-all

# Make sure not to clobber the files being used by current jobs!
if [ -e $sample_list ]; then
    cat << EOM

$sample_list already exists.  Is a job already running?

Wait for the job to finish and remove $vcf_list to start again.

EOM
    exit 1
fi

# Generate samples list for this and subsequent steps
printf "Finding samples...\n"
find ../1b-compress/chr01 -name '*.vcf.xz' | cut -d . -f 4 > $sample_list
tj=$(cat $sample_list | wc -l)
total_jobs=$(echo $tj)   # Get rid of leading whitespace from wc

# Split the find output into small chunks so each job has a quick awk search
# It takes a few seconds to search a file with 1 million lines whereas
# 10k lines is instantaneous.  This cut the compression of 1 million files
# from 25 hours to 12.
max_lines=1000
printf "Splitting...\n"
split -l $max_lines -a 4 -d $sample_list sample-list-
wc -l sample-list-[0-9]*

cd ../..
read -p 'Submit? y/[n] ' submit
if [ 0$submit = 0y ]; then
    set -x
    sbatch --array=1-${total_jobs}%$max_jobs 1c-combine.sbatch
fi
