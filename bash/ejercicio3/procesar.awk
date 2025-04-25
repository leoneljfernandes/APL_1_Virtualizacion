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
    if(length(buscadas) == 0){
        print "No se encontraron coincidencias para las palabras especificadas."
    }
    print "Palabras encontradas:"
    print "Palabra\tCantidad"
    print "---------------------"
    for (p in buscadas) {
        if (buscadas[p] > 0) {
            print p, buscadas[p]
        }
    }
}