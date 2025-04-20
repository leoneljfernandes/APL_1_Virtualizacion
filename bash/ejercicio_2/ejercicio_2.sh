#!/bin/bash

function ayuda() {
    echo "Bienvenido al script de procesamiento de Matrices."
    echo "El mismo realizara el producto escalar y la transposicion de la matriz."
    echo "Puede optar por las siguientes opciones:"
    echo "  -m, --matriz  <directorio>      Especifica el directorio del archivo de la matriz."
    echo "  -p, --producto                  Valor entero para utilizarse en el producto escalar."   
    echo "  -t, --trasponer                 Indica que se debe realizar la operación de trasposición sobre la matriz. (no recibe valor adicional, solo el parámetro)."
    echo "  -s, --separador                 Carácter para utilizarse como separador de columnas.."
    echo "  -h, --help                      Muestra esta ayuda."
}

options=$(getopt -o m:p:ts: --l help,matriz:,producto:,trasponer,separador: -- "$@" 2> /dev/null)
if [ "$?" != "0" ]
then
    echo 'Opciones incorrectas'
    exit 1
fi

eval set -- "$options"

# Procesamos los argumentos
while true
do
    case "$1" in
        -m | --matriz) # case "-e":
            matriz="$2"
            shift 2
            ;;
        -p | --producto)
            producto="$2"
            shift 2
            ;;
        -t | --trasponer)
            trasponer="TRUE"
            shift
            ;;
        -s | --separador)
            separador="$2"
            shift 2
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

#validacion de exclusividad entre producto o transponer
if [ -n "$producto" ] && [ -n "$trasponer" ]; then
    echo "Error: No se puede especificar tanto un producto escalar como una transposición."
    exit 1
fi

#Validar que el parametro de archivo de entrada no este vacio
if [ -z "$matriz" ]; then
    echo "Error: Debe especificar un archivo de entrada."
    exit 1
fi

#Verificamos si el archivo existe
if [ ! -f "$matriz" ]; then
    echo "Error: El archivo $matriz no existe."
    exit 1
fi

#Verificamos si se tienen permisos de lectura en el archivo
if [ ! -r "$matriz" ]; then
    echo "Error: No se tienen permisos de lectura en el archivo $matriz."
    exit 1
fi

#Validar que el archivo de entrada no este vacio
if [ ! -s "$matriz" ]; then
    echo "Error: El archivo $matriz esta vacio."
    exit 1
fi  

#Validar que se indique el separador
if [ "${#separador}" -ne 1 ]; then
    echo "Error: El separador debe ser un único carácter."
    exit 1
fi


# Procesar el archivo
if [ -n "$producto" ]; then
    # Validar que el producto sea un número entero
    if ! [[ "$producto" =~ ^-?[0-9]+$ ]]; then
        echo "Error: El producto escalar debe ser un número entero."
        exit 1
    fi

    echo "Realizando el producto escalar de la matriz $matriz con el valor $producto y separador $separador"
    resultado=$(awk -F "$separador" -v prod="$producto" -v sep="$separador" '{
        for(i=1;i<=NF;i++){
            printf "%s%s", $i * prod, (i==NF ? ORS : sep)
        }
    }' "$matriz")

    nombre_base=$(basename "$matriz")
    archivo_salida="./archivos/salida.$nombre_base"
    echo "$resultado" > "$archivo_salida"

elif [ -n "$trasponer" ]; then
    # Realizar la transposición
    echo "Realizando la transposición de la matriz $matriz con separador $separador"
    resultado=$(awk -F "$separador" -v sep="$separador" '{
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
    }' "$matriz")


    nombre_base=$(basename "$matriz")
    archivo_salida="./archivos/salida.$nombre_base"
    echo "$resultado" > "$archivo_salida"
fi




