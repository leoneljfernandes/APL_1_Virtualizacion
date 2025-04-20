#!/bin/bash

function ayuda() {
    echo "Bienvenido al script contador de palabras."
    echo "Puede optar por las siguientes opciones:"
    echo "  -d, --directorio <directorio>   Especifica el directorio donde se contengan textos a analizar."
    echo "  -p, --palabras                  Lista de palabras a contar separadas por comas."   
    echo "  -a, --archivos                  Lista de extensiones de archivos a buscar separadas por comas."
    echo "  -h, --help                      Muestra esta ayuda."
}

options=$(getopt -o d:p:a:h --l help,directorio:,palabras:,archivos: -- "$@" 2> /dev/null)
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
        -d | --directorio) # case "-e":
            directorio="$2"
            shift 2
            ;;
        -p | --palabras)
            palabras="$2"
            shift 2
            ;;
        -a | --archivos)
            IFS=',' read -ra extensiones <<< "$2" #Guardamos las extensiones en un array
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

# Validar que esten todos los parametros

if [ -z "$directorio" ]; then
    echo "Error: Debe especificar un directorio."
    exit 1
fi

if [ -z "$palabras" ]; then
    echo "Error: Debe especificar al menos una palabra a contar."
    exit 1
fi

if [ -z "$extensiones" ]; then
    echo "Error: Debe especificar al menos una extension de archivos."
    exit 1
fi

if [ ! -d "$directorio" ] || [ ! -r "$directorio" ]; then
    echo "Error: El directorio no existe o no tiene permisos de lectura."
    exit 1
fi


# Acumulamos todos los archivos con extensión deseada
archivos=()
for ext in "${extensiones[@]}"; do
    ext="${ext#.}"
    echo "Buscando archivos .$ext en $directorio..."
    while IFS= read -r archivo; do
        archivos+=("$archivo")
    done < <(find "$directorio" -type f -name "*.$ext")
done

# Ejecutamos AWK una sola vez sobre todos los archivos encontrados
awk -F ' ' -f procesar.awk -v palabras="$palabras" "${archivos[@]}"
