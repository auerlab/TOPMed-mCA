#!/bin/sh -e

sed -e 's|,[01]/[01]||g' snpids.tsv > snpids-stripped.tsv
