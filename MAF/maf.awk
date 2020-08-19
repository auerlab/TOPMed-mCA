#############################################################################
#   Description:
#       Filter VCFs for sites with MAF >= 0.01
#
#   History: 
#   Date        Name        Modification
#   2020-08-19  Jason Bacon Begin
#############################################################################

BEGIN {
    chr="";
}
{
    if ( $1 != chr )
    {
	chr=$1;
	file=chr ".out";
	printf("Switching to chr %s file %s\n", chr, file);
    }
    while ( (getline maf_pos < file != 0) && (maf_pos < $2) )
    {
	# printf("Skipping %s\n", maf_pos);
    }
    if ( maf_pos == $2 ) print $0;
}

