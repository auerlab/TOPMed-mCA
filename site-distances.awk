BEGIN {
    last_pos = 0;
    min_distance = 1000;
    lt_min_distance = 0;
    ge_min_distance = 0;
}
{
    distance = $2 - last_pos;
    printf("%s %u %u\n", $1, $2, distance);
    if (distance < min_distance)
    {
	++lt_min_distance;
    }
    else
    {
	++ge_min_distance;
    }
    last_pos = $2;
}
END {
    total_pairs = lt_min_distance + ge_min_distance;
    printf("Total site pairs: %u Distances < %u: %u (%f%%)\n",
	    total_pairs,
	    min_distance,
	    lt_min_distance,
	    lt_min_distance / total_pairs * 100.0);
}
