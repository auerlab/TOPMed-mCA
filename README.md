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
are in multi-sample, single-chromosome format, not suitable for haplohseq.

Hence, this pipeline was developed in order to reformat and augment the VCF
data for use with haplohseq.  This includes the following high-level
processing steps:

1. 1a-vcf-split.sbatch

    Split the multi-sample, single-chromosome dbGaP BCF files into
    single-sample, single-chromosome VCF files and combine the results into
    single-sample, multi-chromosome VCFs.

    This step is extremely I/O-intensive, and
    existing tools for processing VCF data lacked the ability to do it
    efficiently.  The largest of the multi-sample BCF files (for chromosome 2)
    is 83 gigabytes and takes approximately 2 days just to read using
    [bcftools](https://github.com/samtools/bcftools).  Extracting the 137,977
    samples one at a time would therefore take approximately 2 * 137,977 days
    = 750 years.  To solve this issue, we developed
    [vcf-split](https://github.com/auerlab/vcf-split), which can extract
    several thousand samples from a multi-sample VCF stream simultaneously,
    while also performing some filtering functions.  We found that some
    bcftools filtering options speed up the program while others slow it down,
    so filtering tasks are divided between bcftools and vcf-split.
    By balancing the workload between bcftools for decoding
    the BCF files and some of the filtering, and vcf-split to extract samples
    and perform the remaining filtering, we were able to generate all of the
    single-sample files in a few weeks.
    
    Combining the single-sample, single-chromosome VCF files into
    single-sample, multiple chromosome files is a simple matter of
    concatenating the single-chromosome files in the correct order.

2. 2a-ad2vcf.sbatch

    Augment the VCF files with allelic depth information.

    Unfortunately, the dbGaP BCF files do not contain allelic depth (allele
    frequencies) in each call.  This is optional information, represented by
    the AD tag in the FORMAT field.  It was omitted during the variant call
    process in order to save space, but is required for haplohseq's
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
    petabytes (2,700 terabytes, 2,700,000 gigabytes).  Using the fastest
    available file transfer tools, it would take well over a year to
    download this much data for processing on our own hardware.
    
    To resolve this issue, SRA files are directly available to virtual machine
    instances on Amazon Web Services (AWS) and Google Cloud Platform (GCP).
    The only tool available for accessing restricted data on AWS and GCP
    at the time of the analysis was Fusera, a fusefs wrapper with
    authentication features for accessing restricted SRA files.
    Fusera was already deprecated
    at the time of our analysis and no alternative was yet available.
    This step proved to be the most challenging due to reliability issues
    with the Fusera mounts, but with additional code features to automatically
    restart processing in the event of failures, we were able to complete it
    in a few months.
    
    The SRA Toolkit has reportedly been updated to provide authenticated
    access to restricted files,
    though we were not able to test it before our access expired. 
    Nonetheless, anyone wishing to access restricted SRA files in the
    future should plan to use the SRA Toolkit.   For running ad2vcf, this
    would involve using "sratools sam-dump" in place of Fusera mounts and
    "samtools view" in our scripts.

3. 3d-filter-sites.sh, 3d-filter-sites.sbatch

    Filter VCF calls for minimum separation of calls (1000 bases for our
    analysis), minimum allele frequency (MAF), and structural variants (79852,
    freeze1).
    
    To reduce noise in the haplohseq and MoCha analyses the resulting AD-enhanced
    VCF files were filtered to keep only sites with a minimum allele frequency
    (MAF) of 0.05 and a minimum separation of 1000 nucleotides.  Other MAF values
    such as 0.01 were also tested and did not prove to have a significant impact
    on haplohseq results.  These filters were implemented by a simple awk
    script.
    
    Additionally, known germ line structural variants were removed in order to
    focus on acquired mutations.  Structural variants are provided by dbGaP
    in the form of BCF files.  We used "bedtools subtract" to remove these
    variants.

4. go-haploh, 4a-haplohseq.sh, 4a-haplohseq.sbatch

    Run haplohseq on the filtered VCF files.
    
    The AD-enhanced, filtered VCF files were then processed through haploseq
    to detect mosaic chromosomal alteration events.  Haplohseq takes many
    parameters.  We experimented with several combinations of the following
    and settled on the values shown below:

    1. Event prevalence = 0.01
    2. Minimum event size = 30 megabases
    3. Minimum depth (coverage of the variant site) = 10

5. 5-mocha.sh, 5-mocha.sbatch

    Run MoCha on the filtered VCF files.
    
    MoCha is another tool for detecting mosaic chromosomal alterations.  We
    ran MoCha on the same filtered VCF files in order to compare the
    sensitivities of the tools and determine the strengths and weaknesses of
    each.

6. Examine results and analyze in GWAS (Genome Wide Association) pipeline
to identify potentially related phenotypes.

## General Notes

Most computational analysis was performed on a [FreeBSD](https://FreeBSD.org)
HPC cluster managed by [SPCM](https://github.com/outpaddling/SPCM) and
running the [slurm](https:https://slurm.schedmd.com/) resource manager.

Code development and testing was performed on a FreeBSD workstation
configured with
[Desktop-installer](https://github.com/outpaddling/desktop-installer) and
using the OpenZFS
file system with lz4 compression.  The compression capabilities of ZFS
significantly reduce disk usage and read/write time for uncompressed
temporary files such as raw VCFs.  This is especially helpful when splitting
the multisample VCFs, since we cannot pipe thousands of VCF streams through
xz processes simultaneously.  We must write raw VCFs and compress them
afterward using reasonable parallelism.

All long-term output files were subsequently compressed with xz, which
provides significantly better compression ratios than lz4, gzip, or bzip2.
(Typically about 40% smaller than gzip).

Filtering reads based on MAPQ in ad2vcf resulted in no noticeable improvement
to the haplohseq results.  Reads for whi, bjm, group3, and group4 were
filtered only for unmapped reads.

## Repository Organization

- Scripts in the top-level directory are part of the primary analysis pipeline.
- Scripts used for exploration are found under Utils.
- Primary data are stored under Data.
- Analysis logs are under Logs.
- Metadata to be saved for replicating the analysis are under Save.

## Software Requirements

All software required for this analysis can be installed on FreeBSD with
the following command:

```
pkg install sra-tools bcftools vcf-split samtools mawk bedtools \
    vcf2hap ad2vcf haplohseq bio-mocha
```

General tools such as awk, sed, sort, xz, etc. are included in the FreeBSD
base installation.  Mawk outperforms BSD and GNU awk and may be used as
a drop-in replacement to speed up some scripts, though this will have only
a minor impact on overall analysis time as awk is generally not a bottleneck.

Most FreeBSD ports are also available in dports on Dragonfly BSD, and many
are available in pkgsrc, a package manager with stringent quality assurance
that supports virtually any POSIX platform.
