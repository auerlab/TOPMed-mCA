#!/bin/sh -e

##########################################################################
#
#   Example MoCha script
#
#   For detailed information, see https://github.com/freeseek/mocha
#       
#   History:
#   Date        Name        Modification
#   2021-11-29  Ying Zhou   Begin
#   2021-11-29  Jason Bacon Generalize for portability
##########################################################################

##########################################################################
#   Main
##########################################################################

## REF
ref=GCA_000001405.15_GRCh38_no_alt_analysis_set.fna
site=https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/001/405/GCA_000001405.15_GRCh38/seqs_for_alignment_pipelines.ucsc_ids
if [ ! -e Data/5-mocha/$ref ]; then
    cd Data/5-mocha
    srun curl -C - -O $site/$ref.gz
    srun gunzip $ref.gz
    cd ../..
fi

# Create index

samples=$(cat Data/1c-combine/sample-list-all | wc -l)
samples=$(echo $samples)
set -x
sbatch --array=1-$samples ./5-mocha.sbatch
