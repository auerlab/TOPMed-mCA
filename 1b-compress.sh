#!/usr/bin/env bash

set -e

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
    printf "Usage: $0 total-jobs max-jobs\n"
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

cd Split-vcfs
mkdir -p SLURM-compress-outputs
find . -name '*.vcf' | head -n $total_jobs > vcf-list.txt
wc -l vcf-list.txt

batch_file=compress-tmp.sbatch
cat << EOM > $batch_file
#!/usr/bin/env bash

#SBATCH --array=1-${total_jobs}%$max_jobs
#SBATCH --output=SLURM-compress-outputs/compress-%A_%a.out
#SBATCH --error=SLURM-compress-outputs/compress-%A_%a.err

vcfs=(\`cat vcf-list.txt\`)
subscript=\$((\$SLURM_ARRAY_TASK_ID - 1))
my_vcf=\${vcfs[\$subscript]}
printf "Compressing \$my_vcf...\n"
xz \$my_vcf
EOM

cat $batch_file
read -p 'Submit? y/[n] ' submit
if [ 0$submit = 0y ]; then
    sbatch $batch_file
fi
