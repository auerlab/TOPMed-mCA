#############################################################################
#   Description:
#  
#   Arguments:
#
#   Returns:
#
#   History: 
#   Date        Name        Modification
#   2022-01-17  Jason Wayne BaconBegin
#############################################################################

BEGIN {
    printf("ID strings: %s\n", id_str);
    split(id_str, id_list, " ");
    # print id_list[1];
}
{
    #print $3;
    #print id_str;
}
id_str ~ $3 {
    print $1, $2, $3;
}
END {
}

