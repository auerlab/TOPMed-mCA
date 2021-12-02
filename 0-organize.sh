#!/bin/sh

# Universal
mkdir -p Data Logs
for stage in 1-vcf-split 2-ad2vcf; do
    mkdir -p Data/$stage Logs/$stage
done

# Local to UWM: Adjust to your site
cd Data
ln -sf ../../../SRR6990379/ Alignments
ln -sf ../../../ncbi/dbGaP-13558/files/71699/topmed-dcc/exchange/phs000964_TOPMed_WGS_JHS/Combined_Study_Data/Genotypes/freeze.8/phased \
    Raw-bcfs

sample_id_file=samples.txt
ls Alignments/*.cram | awk -F '[/\.]' '{ print $2 }' > $sample_id_file
