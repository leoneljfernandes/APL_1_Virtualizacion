#!/bin/bash

function ayuda() {
    echo "Bienvenido al script contador de palabras."
    echo "Debe especificar los siguientes argumentos:"
    echo "  -d, --directorio <directorio>   Especifica el directorio donde se contengan textos a analizar."
    echo "  -p, --palabras                  Lista de palabras a contar separadas por comas sin espacio."   
    echo "  -a, --archivos                  Lista de extensiones de archivos a buscar separadas por comas."
    echo "  -h, --help                      Muestra esta ayuda."
}

function validarParametros(){
    
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

    #validar que el directorio este vacio
    if [ -z "$(ls -A "$directorio")" ]; then
        echo "Error: El directorio está vacío."
        exit 1
    fi

    if [ ! -d "$directorio" ] || [ ! -r "$directorio" ]; then
        echo "Error: El directorio no existe o no tiene permisos de lectura."
        exit 1
    fi
}

function procesarArchivos() {
    archivos=()
    for ext in "${extensiones[@]}"; do
        ext="${ext#.}"
        echo "Buscando archivos .$ext en $directorio..."
        while IFS= read -r archivo; do
            archivos+=("$archivo")
        done < <(find "$directorio" -type f -name "*.$ext")
    done

    if [ ${#archivos[@]} -eq 0 ]; then
        echo "No se encontraron archivos con las extensiones especificadas."
        exit 1
    fi

    awk -F ' ' -v palabras="$palabras" '
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
    END {
        if (length(buscadas) == 0) {
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
    ' "${archivos[@]}"
}

options=$(getopt -o d:p:a:h --long help,directorio:,palabras:,archivos: -- "$@" 2>&1)
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
        -d | --directorio) # case "-e":
            directorio="$2"
            if [[ "$2" == -* ]]; then
                echo "Error: Después de -d debe especificar una ruta válida."
                exit 1
            fi
            shift 2
            ;;
        -p | --palabras)
            if [[ "$2" == -* ]]; then
                echo "Error: Después de -p debe especificar una lista de palabras separadas por comas."
                exit 1
            fi
            palabras="$2"
            shift 2
            ;;
        -a | --archivos)
            if [[ "$2" == -* ]]; then
                echo "Error: Después de -a debe especificar una lista de extensiones separadas por comas."
                exit 1
            fi
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
validarParametros
echo "Validaciones de parametros pasadas correctamente."

procesarArchivos
