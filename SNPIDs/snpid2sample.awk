#############################################################################
#   Description:
#       Search a structural variant VCF stream for SNPIDs (column 3)
#       matching any in the list id_str.  Report NWD IDs for samples
#       in a matching record that have at least 1 variant allele, i.e.
#       0/1, 1/0, or 1/1.
#
#   History: 
#   Date        Name        Modification
#   2022-01-17  Jason Wayne BaconBegin
#############################################################################

$1 == "#CHROM" {
    split($0, id_list);
}
($3 != "") && (id_str ~ $3) {
    printf("%s\t%s\t%s", $1, $2, $3);
    for (c = 10; c <= NF; ++c) {
	if ( $c ~ "1" ) {
	    printf("\t%s,%s", id_list[c], $c);
	}
    }
    printf("\n");
}
