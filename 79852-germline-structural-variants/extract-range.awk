#############################################################################
#   Description:
#  
#   Arguments:
#
#   Returns:
#
#   History: 
#   Date        Name        Modification
#   2021-02-23  Jason Bacon Begin
#############################################################################

{
    # $1 = chr, $2 = pos
    range=$3;
    split(range,a,"[:-]");
    printf("%s\t%u\t%u\n", $1, a[2], a[3]);
}

