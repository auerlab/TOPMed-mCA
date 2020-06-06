#!/bin/sh -e

export PATH=${PATH}:$(pwd)

for round in 1 2 3 4 5; do
    find Split-vcfs -name '*.done' -exec compress-if-needed.sh '{}' \;
done
