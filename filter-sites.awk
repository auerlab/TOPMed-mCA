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
    # Force $1 != chr for first record
    chr = "";
    last_kept_pos = 0;
}
{
    # printf("===\nChecking %s %s\n", $1, $2);
    # chr1, chr2, ...
    if ( $1 != chr )
    {
	# Start of new chromosome in VCF
	chr = $1;
	
	# File with positions where MAF meets criteria
	maf_file = "Filtered-vcfs/" chr "-maf-sites.txt"
	
	# Ensure that next_ok_maf_pos < $2 when starting new chromosome
	next_ok_maf_pos = -1;
	
	last_kept_pos = 0;
    }
    
    # Read more lines from MAF list until pos >= $2 (pos in VCF)
    # Force numeric comparison with + 0
    # printf("'%s' '%s' %s\n", next_ok_maf_pos, $2, next_ok_maf_pos < $2);
    while ( (next_ok_maf_pos + 0 < $2 ) && (getline next_ok_maf_pos < maf_file != 0) )
    {
	# printf("Read %s from %s.\n", next_ok_maf_pos, maf_file);
    }
    
    # Also filter out sites < 1000kb apart
    distance = $2 - last_kept_pos;
    if ( ($2 == next_ok_maf_pos) && (distance >= 1000) )
    {
	print $0;
	# Debug
	# printf("Keep %s,%s  Next OK MAF = %s  Distance from last kept = %s\n", $1, $2, next_ok_maf_pos, distance);
	last_kept_pos = $2;
    }
    else
    {
	# Debug
	# printf("=== Toss %s,%s  Next OK MAF = %s  Distance from last kept = %s\n", $1, $2, next_ok_maf_pos, distance);
    }
}
