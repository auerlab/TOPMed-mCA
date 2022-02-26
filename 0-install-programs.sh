#!/bin/sh -e

# Programs used should all be reported in batch script output using "which"
# grep -h which *.sh *.sbatch | awk '$1 == "which" { print $2 }' | sort | uniq

case $(uname) in
FreeBSD)
    if [ 0"$(node-type)" = 0"head" ]; then
	set -x
	su root -c "cluster-run 'pkg install -y ad2vcf bcftools bedtools haplohseq mawk samtools vcf-split vcf2hap' compute"
    else
	runas root pkg install -y ad2vcf bcftools bedtools haplohseq mawk samtools vcf-split vcf2hap
    fi
    ;;

*)
    printf "$0: $(uname) is not yet supported.\n"
    exit 1

esac
