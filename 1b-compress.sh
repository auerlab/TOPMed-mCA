#!/bin/sh -e

##########################################################################
#   Script description:
#       Generate and launch a batch script to compress vcf-split outputs
#       in parallel.
#       May need to increase MaxJobCount and MaxArraySize
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
dir=Split-vcfs-1st

vcf_list=vcf-list-all
cd $dir
pwd

# Make sure not to clobber the files being used by current jobs!
if [ -e $vcf_list ]; then
    cat << EOM

$vcf_list already exists.  Is a job already running?

Remove it to start again.

EOM
    exit 1
fi
mkdir -p SLURM-compress-outputs
printf "Finding VCFs...\n"
if [ $total_jobs = all ]; then
    find chr* -name '*.vcf' > $vcf_list
    tj=$(cat $vcf_list | wc -l)
    total_jobs=$(echo $tj)   # Get rid of leading whitespace from wc
else
    find chr* -name '*.vcf' | head -n $total_jobs > $vcf_list
fi

# Split the find output into small chunks so each job has a quick awk search
# It takes a few seconds to search a file with 1 million lines whereas
# 10k lines is instantaneous.  This cut the compression of 1 million files
# from 25 hours to 12.
max_lines=10000
printf "Splitting...\n"
split -l $max_lines -a 4 -d $vcf_list vcf-list-
wc -l vcf-list-[0-9]*

batch_file=compress-tmp.sbatch
cat << EOM > $batch_file
#!/bin/sh -e

#SBATCH --array=1-${total_jobs}%$max_jobs
#SBATCH --output=SLURM-compress-outputs/compress-%A_%a.out
#SBATCH --error=SLURM-compress-outputs/compress-%A_%a.err

split_file_num=\$(( (SLURM_ARRAY_TASK_ID - 1) / $max_lines ))
split_file=\$(printf "vcf-list-%04d" \$split_file_num)
line=\$(( (SLURM_ARRAY_TASK_ID - 1) % $max_lines + 1 ))
my_vcf=\$(awk -v line=\$line 'NR == line { print \$1 }' \$split_file)

printf "Compressing \$my_vcf...\n"
xz -f \$my_vcf
EOM

cat $batch_file
read -p 'Submit? y/[n] ' submit
if [ 0$submit = 0y ]; then
    sbatch $batch_file
fi
