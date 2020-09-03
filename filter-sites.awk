#############################################################################
#   Description:
#       Filter VCFs for sites with MAF >= 0.01 and separated by 1000kb
#       or more
#
#       MAF file contains a list of sites with MAF >= 0.01 from
#       3b-find-maf-sites.sbatch
#
#   History: 
#   Date        Name        Modification
#   2020-08-19  Jason Bacon Begin
#############################################################################

BEGIN {
    chr = -1;
    previous_pos = -1000;
}
{
    if ( $1 != chr )
    {
	# Start of new chromosome in VCF
	chr = $1;
	
	# File with positions where MAF meets criteria
	maf_file = "chr" chr "-maf-sites.txt"
	
	# Ensure that maf_pos < $2
	maf_pos = -1;
    }
    
    # Read more lines from MAF list until pos >= $2 (pos in VCF)
    while ( (maf_pos < $2 ) && ((getline maf_pos < maf_file) != 0) )
    {
	# printf("Skipping %s\n", maf_pos);
    }
    
    # Also filter out sites < 1000kb apart
    if ( ($2 == maf_pos) && (maf_pos - previous_pos >= 1000) )
    {
	print $0;
	previous_pos = maf_pos;
    }
}
