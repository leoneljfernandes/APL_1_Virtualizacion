BEGIN {
    n = split(palabras, lista, ",")
    for (i = 1; i <= n; i++) {
        buscadas[lista[i]] = 0
    }
}
{
    for (i = 1; i <= NF; i++) {
        if ($i in buscadas) {
            buscadas[$i]++
        }
    }
}
END{
    for (p in buscadas) {
        if (buscadas[p] > 0) {
            print p, buscadas[p]
        }
    }
}