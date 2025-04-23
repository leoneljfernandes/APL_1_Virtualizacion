{
    for(i=1; i<=NF; i++){
            a[NR,i] = $i
    }
    if(NF > max) max = NF
    filas = NR
}

END {
    for(i=1; i<=max; i++){
        for(j=1; j<=filas; j++){
            printf "%s%s", a[j,i], (j==filas ? "\n" : sep)
        }
    }
}