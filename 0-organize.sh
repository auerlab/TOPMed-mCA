#!/bin/sh

mkdir -p Data Logs
scripts=$(ls [1-9]-*.s* [1-9][a-z]-*.s*)
for script in $scripts; do
    stage=${script%.*}
    mkdir -p Data/$stage Logs/$stage
done
ls Data

# Local to UWM: Adjust to your site
cd Data

sample_id_file=samples.txt
ls Alignments/*.cram | awk -F '[/\.]' '{ print $2 }' > $sample_id_file
