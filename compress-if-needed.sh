#!/bin/sh -e

vcf_file=${1%.done}
if [ -e $vcf_file ]; then
    printf "Compressing $vcf_file...\n"
    xz $vcf_file
fi
