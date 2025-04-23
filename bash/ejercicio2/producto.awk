# producto.awk
BEGIN {
    FS = sep
    OFS = sep
}
{
    for(i=1; i<=NF; i++) {
        printf "%s%s", $i * prod, (i==NF ? ORS : OFS)
    }
}