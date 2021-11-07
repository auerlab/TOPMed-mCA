# Haplohseq-analysis
Haplohseq analysis of TOPMed data

Filtering reads based on MAPQ in ad2vcf resulted in very little improvement
in the haplohseq results.  Reads for whi, bjm, group3, and group4 were
filtered only for unmapped reads.

Scripts in the top-level directory are part of the primary analysis pipeline.

Scripts used for exploration are found under Utils.

Primary data are stored under Data.

Analysis logs are under Logs.

Metadata to be saved for replicating the analysis are under Save.

Most software developed for this project can be installed via FreeBSD ports
on FreeBSD, dports on Dragonfly BSD, or pkgsrc on virtually any POSIX platform.


