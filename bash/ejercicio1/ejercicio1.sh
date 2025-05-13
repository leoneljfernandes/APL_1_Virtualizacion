#!/bin/bash

function ayuda() {
    echo "Bienvenido al script de procesamiento de datos meteorologicos."
    echo "Puede optar por las siguientes opciones:"
    echo "  -d, --directorio <directorio>   Especifica el directorio de trabajo."
    echo "  -a, --archivo <archivo>         Especifica el archivo de salida."   
    echo "  -p, --pantalla <pantalla>       Especifica la salida a pantalla."
    echo "  -h, --help                      Muestra esta ayuda."
    echo "Ejemplo de uso: $0 -d /ruta/al/directorio -a archivo.txt -p pantalla"
    echo "Ejemplo de uso: $0 --directorio /ruta/al/directorio --archivo archivo.txt --pantalla pantalla"
    echo "Ejemplo de uso: $0 -h"
    echo "Ejemplo de uso: $0 --help"
    echo "Si elige obtener el resultado mediante un archivo de salida no sera posible visualizarlo en pantalla."
}

function validacionesDeParametros(){
        #verifico que se haya especificado un directorio
    if [ -z "$directorio" ]; then
        echo "Error: No se ha especificado un directorio."
        exit 1
    fi

    #Verificamos si el directorio existe
    if [ ! -d "$directorio" ]; then
        echo "Error: El directorio $directorio no existe."
        exit 1
    fi

    #Verificamos si se tienen permisos de lectura en el directorio
    if [ ! -r "$directorio" ]; then
        echo "Error: No se tienen permisos de lectura en el directorio $directorio."
        exit 1
    fi

    if [ -z "$(ls -A "$directorio" 2>/dev/null)" ]; then
        echo "Error: El directorio '$directorio' está vacío."
        exit 1
    fi

    if [ -z "$archivo" ] && [ -n "$archivo" ]; then
        echo "Error: No se especifico un archivo de salida."
        exit 1
    fi

    #Verificamos si no se especifico un archivo de salida
    if [ -z "$archivo" ] && [ -z "$pantalla" ]; then
        echo "Error: No se ha especificado una salida (ni archivo ni pantalla)."
        exit 1
    fi

    if [ -n "$archivo" ]; then
        if [ -z "$archivo" ]; then
            echo "Error: No se ha especificado un archivo de salida."
            exit 1
        fi
        
        if [ ! -f "$archivo" ]; then
            touch "$archivo" 2>/dev/null || {
                echo "Error: No se pueden crear archivos en el directorio de destino o no se tienen permisos."
                exit 1
            }
            rm "$archivo"  # Remove the test file
        fi

    fi

    #Validacion de exclusividad entre archivo de salida y pantalla
    if [ -n "$archivo" ] && [ -n "$pantalla" ]; then
        echo "Error: No se puede especificar tanto un archivo de salida como una salida a pantalla."
        exit 1
    fi

}

function escribirResultado(){
    if [ -n "$archivo" ]; then
        echo "$1" >> "$archivo"
    elif [ -n "$pantalla" ]; then
        echo "$1"
    fi
}

options=$(getopt -o d:a:ph --long help,directorio:,archivo:,pantalla -- "$@" 2>&1)
if [ $? -ne 0 ]; then
    # Extraemos el mensaje de error
    error_msg=$(echo "$options" | sed 's/^[^:]*://; s/^ *//')
    
    # Verificamos si el error es por falta de argumento
    if [[ "$error_msg" == *"requires an argument"* ]]; then
        opcionFaltante=$(echo "$error_msg" | grep -oP "'\K[^']+")
        echo "Error: La opción -$opcionFaltante requiere un argumento"
    else
        echo "Error en las opciones: $error_msg"
    fi
    exit 1
fi

eval set -- "$options"

# Procesamos los argumentos
while true
do
    case "$1" in 
        -d | --directorio)
            if [[ "$2" == -* ]]; then
                echo "Error: Se esperaba un argumento para la opción -d/--directorio."
                exit 1
            fi
            directorio="$2"
            shift 2
            ;;
        -a | --archivo)
            if [[ "$2" == -* ]]; then
                echo "Error: Se esperaba un argumento para la opción -a/--archivo."
                exit 1
            fi
            archivo="$2"
            shift 2
            ;;
        -p | --pantalla)
            pantalla="TRUE"
            shift
            ;;
        -h | --help)
            ayuda
            exit 0
            ;;
        --) # case "--":
            shift
            break
            ;;
        *) # default: 
            echo "Error: Opcion no reconocida."
            exit 1
            ;;
    esac
done


validacionesDeParametros
echo "Validaciones de parametros realizadas con exito."


#Debug de salida
echo "Directorio: $directorio"
[ -n "$archivo" ] && echo "Salida en archivo: $archivo"
[ -n "$pantalla" ] && echo "Mostrar en pantalla: $pantalla"


for archivo_csv in "$directorio"/*.csv; do
    # Verificamos que realmente haya archivos .csv
    if [ ! -e "$archivo_csv" ]; then
        echo "No se encontraron archivos CSV en el directorio $directorio."
        exit 1
    fi

    echo "Procesando archivo: $archivo_csv"

    # Verificamos si el archivo tiene permisos de lectura
    if [ ! -r "$archivo_csv" ]; then
        echo "Error: No se tienen permisos de lectura en el archivo $archivo_csv."
        exit 1
    fi
    
    #Realizamos el calculo con AWK
    resultado=$(awk -F ',' '
    BEGIN {
        #inicio awk
    }

    {
        idDisp = $1
        fecha = $2
        hora = $3
        ubicacionDisp = $4
        temperatura = $5

        clave = $2 "-" $4
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
    ' "$archivo_csv")

    escribirResultado "$resultado"

done

