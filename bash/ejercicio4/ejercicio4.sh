#!/bin/bash

function ayuda() {
    echo "Bienvenido al script contador de palabras."
    echo "Debe especificar los siguientes argumentos:"
    echo "  -d, --directorio <directorio>   Especifica el directorio donde se contengan los archivos a analizar."
    echo "  -s, --salida                    Ruta del directorio donde se van a crear los backups."   
    echo "  -c, --cantidad                  Cantidad de archivos a ordenar antes de generar un backup."
    echo "  -k, --kill                      Flag que se utiliza para indicar que el script debe detener el demonio previamente iniciado."
    echo "  -h, --help                      Muestra esta ayuda."
}

function validarParametros(){
    #que el directorio exista
    if [ ! -d "$directorio" ]; then
        echo "El directorio $directorio no existe."
        exit 1
    fi
    #que el directorio no este vacio
    if [ -z "$(ls -A $directorio)" ]; then
        echo "El directorio $directorio esta vacio."
        exit 1
    fi
    #que el directorio tenga permisos de lectura
    if [ ! -r "$directorio" ]; then
        echo "No tiene permisos de lectura en el directorio $directorio."
        exit 1
    fi
    #que el directorio tenga permisos de escritura
    if [ ! -w "$directorio" ]; then
        echo "No tiene permisos de escritura en el directorio $directorio."
        exit 1
    fi

    #que la ruta de salida exista
    if [ ! -d "$salida" ]; then
        echo "El directorio $salida no existe."
        exit 1
    fi

    #que la salida tenga permisos de escritura
    if [ ! -w "$salida" ]; then
        echo "No tiene permisos de escritura en el directorio $salida."
        exit 1
    fi

    #que la cantidad de archivos sea un numero
    if ! [[ "$cantidad" =~ ^[0-9]+$ ]]; then
        echo "La cantidad de archivos debe ser un numero."
        exit 1
    fi
    #que la cantidad de archivos sea mayor a 0
    if [ "$cantidad" -le 0 ]; then
        echo "La cantidad de archivos debe ser mayor a 0."
        exit 1
    fi

    #si especifico kill, no puedo especificar directorio, salida ni cantidad
    if [ "$kill" = true ]; then
        if [ -n "$directorio" ] || [ -n "$salida" ] || [ -n "$cantidad" ]; then
            echo "No se pueden especificar los argumentos -d, -s o -c junto con -k."
            exit 1
        fi
    fi
}

options=$(getopt -o d:s:c:kh --long help,directorio:,salida:,kill -- "$@" 2>&1)
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

while true
do
    case "$1" in
        -d | --directorio) # case "-e":
            if [[ "$2" == -* ]]; then
                echo "Error: Después de -d o --directorio debe especificar una ruta válida."
                exit 1
            fi
            directorio="$2"
            shift 2
            ;;
        -s | --salida)
            if [[ "$2" == -* ]]; then
                echo "Error: Después de -s o --salida debe especificar un directorio de salida."
                exit 1
            fi
            palabras="$2"
            shift 2
            ;;
        -c | --cantidad)
            if [[ "$2" == -* ]]; then
                echo "Error: Después de -c o --cantidad debe especificar una cantidad de archivos."
                exit 1
            fi
            IFS=',' read -ra extensiones <<< "$2" #Guardamos las extensiones en un array
            shift 2
            ;;
                -c | --cantidad)
            if [[ "$2" == -* ]]; then
                echo "Error: Después de -c o --cantidad debe especificar una cantidad de archivos."
                exit 1
            fi
            IFS=',' read -ra extensiones <<< "$2" #Guardamos las extensiones en un array
            shift 2
            ;;
        -k | --kill)
            kill=true
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

validarParametros
echo "Validacion de parametros correcta."

(
    exec > /dev/null 2>&1

    
)