# TOPMed-mCA

## Overview

This repository houses the tools for Mosaic Chromosomal Alteration (mCA)
analysis of TOPMed whole genome sequence data presented in (paper to be named).

The project is a collaboration among the following institutions:

- University of Wisconsin -- Milwaukee
- Medical College of Wisconsin
- MD Anderson Cancer Center
- Fred Hutchinson Cancer Research Center
- University of Washington
- University of Michigan
- National Heart Lung and Blood Institute

The aim of this analysis is to process human genome data from the Sequence
Read Archive (SRA) and the database of Genotypes and Phenotypes (dbGaP)
through haplohseq, a tool that detects allelic imbalance in impure cell
samples with potentially very low aberrant cell percentages, and MoCha, a
similar tool for detecting such alterations.

[https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5039922/](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5039922/)

[https://sites.google.com/site/integrativecancergenomics/software/haplohseq](https://sites.google.com/site/integrativecancergenomics/software/haplohseq)

[https://software.broadinstitute.org/software/mocha/](https://software.broadinstitute.org/software/mocha/)

## Processing

Haplohseq takes as input a single-sample, multi-chromosome VCF (variant
call format) file containing allele frequencies for each variant call.
Haplohseq can also function using micro-array data.

Variant calls for 137,977 human genomes from TOPMed were available on dbGaP
in the form of BCF (binary variant format, a compressed version of VCF)
files.  Unfortunately, these BCF files do not contain allele frequencies and
are in the wrong format for haplohseq (multi-sample, single-chromosome).

Hence, this pipeline was developed in order to reformat and augment the VCF
data for use with haplohseq.  This includes the following high-level
processing steps:

1. Split the multi-sample, single-chromosome dbGaP BCFs info single-sample,
single-chromosome VCF files and combine the results into single-sample,
multi-chromosome VCFs.

    This step is extremely I/O-intensive, and
    existing tools for processing VCF data lacked the ability to do it
    efficiently.  The largest of the multi-sample BCF files (for chromosome 2)
    is 83 gigabytes and takes approximately 2 days to read using
    [bcftools](https://github.com/samtools/bcftools).  Extracting the 137,977
    samples one at a time would therefore take approximately 750 years.  To
    solve this issue, we developed
    [vcf-split](https://github.com/auerlab/vcf-split), which can extract
    several thousand samples from a multi-sample VCF stream simultaneously,
    while also performing some filtering functions such as discarding
    homozygous sites.  By balancing the workload between bcftools for decoding
    the BCF files and some of the filtering, and vcf-split to extract samples
    and perform the remaining filtering, we were able to generate all of the
    single-sample files in a few weeks.
    
    Combining the single-sample, single-chromosome VCF files into single-sample,
    multiple chromosome files is a simple matter of concatenating the
    single-chromosome files in the correct order.

2. Augment the VCF files with allelic depth information.

    Unfortunately, the dbGaP BCF files do not contain allelic depth (allele
    frequencies) in each call.  This information is needed for haplohseq's
    statistical model to detect imbalances.
    
    One option would be to simply rerun the variant calling pipeline and
    include allelic depth in the VCF output, but this would be enormously
    expensive.
    
    To solve this issue as quickly and efficiently as possible, we
    developed [ad2vcf](https://github.com/auerlab/ad2vcf), a tool to extract
    allelic depth for each call in a VCF from Sequence Alignment Map (SAM)
    files and add it to the VCF.

    The alignment files corresponding to our dbGaP BCFs are available from
    the SRA in the form of CRAM (a highly compressed form of SAM format)
    files.  The CRAM files for all 137,977 samples total roughly 2.7
    petabytes.  Using the fastest available file transfer tools, it would
    take well over a year to download this much data.
    
    To avoid this issue, SRA files are directly available to virtual machine
    instances on Amazon Web Services (AWS) and Google Cloud Platform (GCP).
    The only tool available for accessing restricted data on AWS and GCP
    at the time of the analysis was Fusera, a fusefs wrapper with
    authentication features for SRA access.  Fusera was already deprecated
    at the time of our analysis and no alternative was yet available.
    The SRA Toolkit has reportedly been updated to provide this access,
    though we were not able to test it before our access expired. 
    Nonetheless, anyone wishing to reproduce our results in the future should
    plan to use the "sratools sam-dump" in place of Fusera and
    "samtools view" in our scripts.

3. Filter VCF calls for minimum separation of calls (1000 bases for our
analysis), minimum allele frequency (MAF), and structural variants (79852,
freeze1).

4. Run haplohseq on the filtered VCF files.

5. Run MoCha on the filtered VCF files.

6. Examine results and analyze in GWAS (Genome Wide Association) pipeline
to identify potentially related phenotypes.

## General Notes

Most computational analysis was performed on a [FreeBSD](https://FreeBSD.org)
HPC cluster managed by [SPCM](https://github.com/outpaddling/SPCM).
Code development and testing was performed on a FreeBSD workstation
configured with
[Desktop-installer](https://github.com/outpaddling/desktop-installer). 

Storage utilized the OpenZFS
file system with lz4 compression.  The compression capabilities of ZFS
significantly reduce disk usage and read/write time for uncompressed
temporary files such as VCFs.  This is especially helpful when splitting
the multisample VCFs, since we cannot pipe thousands of VCF streams through
xz processes at once.  We must write raw VCFs and compress them afterward
using reasonable parallism.

All output files were subsequently compressed with xz, which provides
significantly better compression ratios than lz4, gzip, or bzip2. 
(Typically about 40% smaller than gzip).

Filtering reads based on MAPQ in ad2vcf resulted in very little improvement
in the haplohseq results.  Reads for whi, bjm, group3, and group4 were
filtered only for unmapped reads.

## Repository Organization

- Scripts in the top-level directory are part of the primary analysis pipeline.
- Scripts used for exploration are found under Utils.
- Primary data are stored under Data.
- Analysis logs are under Logs.
- Metadata to be saved for replicating the analysis are under Save.

## Software Requirements

Most software developed for this project can be installed via FreeBSD ports
on FreeBSD, dports on Dragonfly BSD, or pkgsrc on virtually any POSIX
platform.
