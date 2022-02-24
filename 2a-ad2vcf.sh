#!/bin/sh -e

jobs=$(ls Data/1c-combine/*.vcf.xz | wc -l)
jobs=$(echo $jobs)  # Remove leading space from wc
printf "$jobs\n"
sbatch 2a-ad2vcf.sbatch --array=1-$jobs%50
