#############################################################################
#   Description:
#  
#   Arguments:
#
#   Returns:
#
#   History: 
#   Date        Name        Modification
#   2022-01-18  Jason Wayne BaconBegin
#############################################################################

$1 == "#CHROM" {
    for (c = 10; c <= NF; ++c) {
	if ( $c == nwdid ) {
	    printf("%s is in column %s.\n", $c, c);
	    break;
	}
    }
}
$3 == snpid {
    printf("Column %s for %s is %s.\n", c, snpid, $c);
    exit;
}
