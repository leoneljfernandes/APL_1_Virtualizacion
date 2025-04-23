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

function validacionDeMatriz(){
    primer_fila_cols=$(head -n 1 "$matriz" | awk -F "$separador" '{print NF}')

    # Validamos que la matriz sea válida llamando al script awk externo
    awk -F "$separador" -v primer_fila_cols="$primer_fila_cols" -v sep="$separador" -f validarMatriz.awk "$matriz"

    if [ $? -ne 0 ]; then
        echo "Error: La matriz en el archivo $matriz no es válida."
        exit 1
    fi
}

function validacionesDeParametros(){
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

    #Validar que el separador no este vacio
    if [ -z "$separador" ]; then
        echo "Error: Debe especificar un separador."
        exit 1
    fi  

    #Validar que se indique el separador
    if [ "${#separador}" -ne 1 ]; then
        echo "Error: El separador debe ser un único carácter."
        exit 1
    fi

    #Valido los separadores que no sean numeros o "-"
    if [[ "$separador" =~ [0-9] ]]; then
        echo "Error: El separador no puede ser un número."
        exit 1
    fi
}

options=$(getopt -o m:p:ts:h --long matriz:,producto:,trasponer,separador:,help -n "$0" -- "$@" 2>&1)
if [ $? -ne 0 ]; then
    # Extraemos el mensaje de error limpio
    error_msg=$(echo "$options" | sed -e 's/^[^:]*://' -e 's/^ *//')
    
    # Verificamos si el error es por falta de argumento
    if [[ "$error_msg" == *"requires an argument"* ]]; then
        option_missing=$(echo "$error_msg" | grep -oP "'\K[^']+")
        echo "Error: La opción -$option_missing requiere un valor"
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
        -m | --matriz) # case "-e":
            if [[ "$2" == -* ]]; then
                echo "Error: Después de -m debe especificar una ruta válida."
                exit 1
            fi
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
            if [[ "$2" == -* ]]; then
                echo "Error: Después de -s debe especificar un separador distinto de "-" ."
                exit 1
            fi
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

# Call validaciones
validacionesDeParametros
echo "Validaciones de parametros pasadas correctamente."

validacionDeMatriz
echo "Validacion de matriz pasada correctamente."


# Procesar el archivo
if [ -n "$producto" ]; then
    # Validar que el producto sea un número entero
    if ! [[ "$producto" =~ ^-?[0-9]+$ ]]; then
        echo "Error: El producto escalar debe ser un número entero."
        exit 1
    fi

    echo "Realizando el producto escalar de la matriz $matriz con el valor $producto y separador $separador"
    
    resultado=$(awk -v prod="$producto" -v sep="$separador" -f producto.awk "$matriz")

    nombre_base=$(basename "$matriz")
    archivo_salida="./archivos/salida.$nombre_base"
    echo "$resultado" > "$archivo_salida"

elif [ -n "$trasponer" ]; then
    # Realizar la transposición
    echo "Realizando la transposición de la matriz $matriz con separador $separador"

    resultado=$(awk -F "$separador" -v sep="$separador" -f trasponer.awk "$matriz")

    nombre_base=$(basename "$matriz")
    archivo_salida="./archivos/salida.$nombre_base"
    echo "$resultado" > "$archivo_salida"
fi




