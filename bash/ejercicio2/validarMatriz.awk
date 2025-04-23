#!/usr/bin/awk -f
BEGIN {
    fila = 0
    error = 0
}
{
    #valido que el separador pasado por parametro sea el correcto en el archivo
    if(index($0,sep) == 0){
        print "Error: El separador no coincide en el archivo"
        error = 1
        exit 1
    }

    fila++
    # Verificar número de columnas
    if (NF != primer_fila_cols) {
        print "Error: La fila " fila " tiene " NF " columnas, pero se esperaban " primer_fila_cols
        error = 1
        exit 1
    }

    
    # Verificar valores numéricos
    for (i=1; i<=NF; i++) {
        # Permitimos números enteros y decimales, positivos y negativos
        if ($i !~ /^-?[0-9]+([.][0-9]+)?$/) {
            print "Error: Valor no numérico encontrado en fila " fila ", columna " i ": \"" $i "\""
            error = 1
            exit 1
        }
    }
}
END {
    if (error) exit 1
}