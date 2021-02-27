#!/bin/sh -e

##########################################################################
#   Script description:
#       Generate and launch a batch script to combine vcf-split outputs
#       in parallel.
#       May need to increase SLURM MaxJobCount and MaxArraySize
#       Also see SLURM high throughput tuning guide to avoid scheduler
#       timeouts
#
#   History:
#   Date        Name        Modification
#   2020-06-16  Jason Bacon Begin
##########################################################################

usage()
{
    printf "Usage: $0 total-jobs max-parallel-jobs\n"
    exit 1
}


##########################################################################
#   Main
##########################################################################

if [ $# != 2 ]; then
    usage
fi

total_jobs=$1
max_jobs=$2
dir=Split-vcfs

sample_list=sample-list-all
mkdir -p $dir
cd $dir
pwd

# Make sure not to clobber the files being used by current jobs!
if [ -e $sample_list ]; then
    cat << EOM

$sample_list already exists.  Is a job already running?

Remove it to start again.

EOM
    exit 1
fi
mkdir -p SLURM-combine-outputs Combined
printf "Finding samples...\n"
if [ $total_jobs = all ]; then
    find chr01 -name '*.vcf.xz' | cut -d . -f 2 > $sample_list
    tj=$(cat $sample_list | wc -l)
    total_jobs=$(echo $tj)   # Get rid of leading whitespace from wc
else
    find chr01 -name '*.vcf.xz' | cut -d . -f 2 | head -n $total_jobs > $sample_list
fi

# Split the find output into small chunks so each job has a quick awk search
# It takes a few seconds to search a file with 1 million lines whereas
# 10k lines is instantaneous.  This cut the compression of 1 million files
# from 25 hours to 12.
max_lines=1000
printf "Splitting...\n"
split -l $max_lines -a 4 -d $sample_list sample-list-
wc -l sample-list-[0-9]*

batch_file=combine-tmp.sbatch
cat << EOM > $batch_file
#!/bin/sh -e

#SBATCH --array=1-${total_jobs}%$max_jobs
#SBATCH --output=SLURM-combine-outputs/combine-%A_%a.out
#SBATCH --error=SLURM-combine-outputs/combine-%A_%a.err

split_file_num=\$(( (SLURM_ARRAY_TASK_ID - 1) / $max_lines ))
split_file=\$(printf "sample-list-%04d" \$split_file_num)
line=\$(( (SLURM_ARRAY_TASK_ID - 1) % $max_lines + 1 ))
my_sample=\$(awk -v line=\$line 'NR == line { print \$1 }' \$split_file)

sources=\$(ls chr*/chr*.\$my_sample.vcf.xz)
printf "Combining \$sources...\n"
# FIXME: Strip headers from all but first file
# xzcat \$sources | xz -cf > Combined/combined.\$my_sample.vcf.xz
EOM

cat $batch_file
read -p 'Submit? y/[n] ' submit
if [ 0$submit = 0y ]; then
    sbatch $batch_file
fi
