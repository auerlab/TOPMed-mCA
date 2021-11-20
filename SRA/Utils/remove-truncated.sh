#!/bin/sh -e

for file in $(awk '$2 != 23 { print $1 }' missing-chroms.txt); do
    path=$(find Data -name $file)
    echo $path
    dir=$(dirname $path)
    mkdir -p $dir/Truncated
    mv $path $dir/Truncated
done
