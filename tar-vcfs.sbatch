#!/bin/sh -e

#SBATCH --nodelist=compute-004

cd Split-vcfs
for chr in 14 15 16 17 18 19 20 21 22 X; do
    printf "Packing chr$chr...\n"
    tar cf ~/Data/TOPMed/Jobs/Haplohseq-analysis/Split-vcfs/chr$chr.tar \
	chr$chr
done
