#!/bin/sh -e

##########################################################################
#
#   Validate structure of AD-enhanced VCFs before running haplohseq
#   This is redundant since each VCF is validated the same way on
#   AWS after ad2vcf completes
#       
#   All necessary tools are assumed to be in PATH.  If this is not
#   the case, add whatever code is needed here to gain access.
#   (Adding such code to your .bashrc or other startup script is
#   generally a bad idea since it's too complicated to support
#   every program with one environment.)
#
#   History:
#   Date        Name        Modification
#   2020-09-13  Jason Bacon Begin
##########################################################################

#SBATCH --array=1-23%100
#SBATCH --output=Logs/2-ad2vcf/validate-vcfs-%A_%a.out
#SBATCH --error=Logs/2-ad2vcf/validate-vcfs-%A_%a.err

##########################################################################
#   Main
##########################################################################

: ${SLURM_ARRAY_TASK_ID:=1}

# These scripts were developed on a FreeBSD/SPCM cluster where all software is
# installed via FreeBSD ports into the default PATH.  If you need to load
# an environment module, activate a conda environent, etc. to gain access
# to software used below, do it here.

# Document software versions used for publication
uname -a
pwd

# Make sure --array above matches the # of samples
my_sample=$(./select-sample.sh $SLURM_ARRAY_TASK_ID)
printf "Processing $my_sample...\n"

raw_vcf="Data/1-vcf-split/Combined/combined.$my_sample.vcf.xz"
ad_vcf="Data/2-ad2vcf/combined.$my_sample-ad.vcf.xz"

last_line_ad=$(xzcat $ad_vcf | tail -n 1)

cols=$(echo $last_line_ad | awk '{ print NF }')
if [ $cols != 10 ]; then
    printf "Last line is truncated.  Only $cols columns, should be 10.\n"
    $mv $ad_vcf $ad_vcf.corrupt
    exit
fi

printf "Last line has all columns.\n"
last_field=$(echo $last_line_ad | awk '{ print $10 }')
ad=$(echo $last_field | awk -F : '{ print $2 }')
ref=$(echo $ad | awk -F , '{ print $1 }')
alt=$(echo $ad | awk -F , '{ print $2 }')
dp=$(echo $last_field | awk -F : '{ print $3 }')
if [ $((ref + alt)) != $dp ]; then
    printf "ref + alt does not match dp\n"
    $mv $ad_vcf $ad_vcf.corrupt
    exit
else
    printf "ref + alt matches dp\n"
fi

# Check for match in last POS between pre and post ad2vcf?
last_line_raw=$(xzcat $raw_vcf | tail -n 1)
last_chr_raw=$(echo $last_line_raw | awk '{ print $1 }')
last_chr_ad=$(echo $last_line_ad | awk '{ print $1 }')
if [ $last_chr_ad != $last_chr_raw ]; then
    printf "Final chromosomes do not match: $last_chr_ad $last_chr_raw\n"
    $mv $ad_vcf $ad_vcf.corrupt
    exit
fi

printf "Final chromosomes match.\n"
last_pos_ad=$(echo $last_line_ad | awk '{ print $2 }')
last_pos_raw=$(echo $last_line_raw | awk '{ print $2 }')

if [ $last_pos_ad != $last_pos_raw ]; then
    printf "Final positions do not match: $last_pos_ad $last_pos_raw\n"
    $mv $ad_vcf $ad_vcf.corrupt
    exit
else
    printf "Final positions match.\n"
fi
