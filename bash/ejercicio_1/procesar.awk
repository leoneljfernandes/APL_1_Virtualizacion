BEGIN{
    #inicio awk
}

{
    idDisp = $1
    fecha = $2
    hora = $3
    ubicacionDisp = $4
    temperatura = $5
    
    #Formo clave compuesta por fecha y ubicacion
    clave = $2 "-" $4

    #Paso la temperatura de texto a numero
    temp = $5 + 0

    suma[clave] += temp
    cuenta[clave]++

    if ((clave in max) == 0 || temp > max[clave]) {
        max[clave] = temp
    }

    if ((clave in min) == 0 || temp < min[clave]) {
        min[clave] = temp
    }

    fechas[fecha]
    ubicaciones[clave]
    
}

END {
    #Formateo en JSON
    print "{"
    print "  \"fechas\": {"

    sep_fecha = ""
    for (f in fechas) {
        printf "%s    \"%s\": {\n", sep_fecha, f
        sep_fecha = ",\n"

        sep_ubic = ""
        for (u in ubicaciones) {
            split(u, partes, "-")
            fecha_u = partes[1]
            ubic = partes[2]

            if (fecha_u != f) continue

            clave = fecha_u "-" ubic
            prom = suma[clave] / cuenta[clave]

            printf "%s      \"%s\": {\n", sep_ubic, ubic
            printf "        \"Min\": %.2f,\n", min[clave]
            printf "        \"Max\": %.2f,\n", max[clave]
            printf "        \"Promedio\": %.2f\n", prom
            printf "      }"
            sep_ubic = ",\n"
        }
        print "\n    }"
    }

    print "\n  }"
    print "}"
}