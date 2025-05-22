#!/bin/bash

# Integrantes del grupo:
# - Berti Rodrigo
# - Burnowicz Alejo
# - Fernandes Leonel
# - Federico Agustin

# Variables globales
PID_DIR="/tmp"
SCRIPT_NAME=$(basename "$0")
SELF_PATH="$(realpath "$0")"

# Función para mostrar uso
function mostrar_uso() {
    echo "Bienvenido al script de monitoreo de directorios."
    echo "El mismo se encargara de reorganizar los archivos sueltos en un directorio espefico en carpetas en base a sus extenciones."
    echo "Ademas, tras un numero de archivos movidos especificado por el usuario, se generara un backup en forma de zip en un directorio espeficiado"
    echo "Al ser un proceso DEMONIO, este debe ser detenido utilizando la opcion kill que se le especificara mas adelante (ademas de requerir que se especifique el directorio)"
    echo "Puede optar por las siguientes opciones:"
    echo "  -d / --directorio  <Directorio>      Especifica el directorio que sera supervisado."
    echo "  -s / --salida <Directorio>           Especifica el directorio donde se realizara el backup correspondiente"   
    echo "  -c / --cantidad <Numero entero>      Cantidad de archivos necesarios para generar un backup"
    echo "  -k / --kill                          Bandera indicando que un proceso ejercicio4.ps1 debe ser terminado"
    echo "  -h / --help                          Muestra esta ayuda."
    echo "Ejemplo:                               ./ejercicio4.ps1 -directorio './Directorio' -salida './Backup' -cantidad 20"
    echo "Ejemplo:                               ./ejercicio4.ps1 -directorio './Directorio' -kill"
    exit 0
}

# Función para lanzar el demonio en segundo plano
function lanzar_demonio() {
    nohup "$SELF_PATH" --daemon "$@" > /dev/null 2>&1 &
    echo "Demonio lanzado para el directorio $DIRECTORIO"
    exit 0

}

# Función para detener el demonio
function detener_demonio() {
    PID_FILE="$PID_DIR/$(basename "$DIRECTORIO").pid"
    if [[ -f "$PID_FILE" ]]; then
        PID=$(sed -n "1p" "$PID_FILE")
        #echo "$PID"
        PIDINOTIFY=$(sed -n "2p" "$PID_FILE")
        #echo "$PIDNOTIFY"
        PIDINOTIFY1=$(sed -n "3p" "$PID_FILE")
        echo "$PIDNOTIFY1"
        if (kill "$PID" 2>/dev/null)  & (kill "$PIDINOTIFY" 2>/dev/null) & (kill "$PIDINOTIFY1" 2>/dev/null); then
            echo "Demonio detenido correctamente."
            rm -f "$PID_FILE"
        else
            echo "No se pudo detener el demonio."
        fi
    else
        echo "No hay demonio corriendo para el directorio $DIRECTORIO."
    fi
    exit 0
}

# Función principal del demonio

function demonio() {
    PID_FILE="$PID_DIR/$(basename "$DIRECTORIO").pid"
    echo $$ >> "$PID_FILE"
    echo "PID_DIR: $$"
    bandera=0

    # Ordenar archivos existentes antes de empezar
    ordenar_archivos

    bandera=1

    # Iniciar inotifywait como coproc
    coproc INOTIFY_PROC { inotifywait -m -e create,moved_to --format "%f" "$DIRECTORIO"; }
    INOTIFY_PID=$INOTIFY_PROC_PID
    echo "$INOTIFY_PID">> "$PID_FILE"
    # echo "INOTIFY_PID: $INOTIFY_PID"
    var1=1
    let INOTIFY_PID1=$var1+$INOTIFY_PID
    echo "$INOTIFY_PID1">>"$PID_FILE"
    echo "INOTIFY_PID1: $INOTIFY_PID1"
   # kill $INOTIFY_PID
    echo "INOTIFY_PID:$INOTIFY_PID"


    # Asegurar que se limpie todo al terminar
    trap 'echo "Saliendo..."; kill "$INOTIFY_PID" 2>/dev/null; rm -f "$PID_FILE"; exit 0' SIGTERM SIGINT EXIT

    while read -r ARCHIVO <&"${INOTIFY_PROC[0]}"; do
        if [[ ! -f "$PID_FILE" ]]; then
            echo "Señal de parada detectada. Terminando demonio..."
            break
        fi
        procesar_archivo "$ARCHIVO"
    done

    # Redundancia por seguridad (en caso de no entrar en trap)
    kill "$INOTIFY_PID1" 2>/dev/null
    wait "$INOTIFY_PID1" 2>/dev/null
    rm -f "$PID_FILE"
    echo "Demonio terminado."
}

# Función para ordenar archivos existentes
function ordenar_archivos() {
    for archivo in "$DIRECTORIO"/*; do
        if [[ -f "$archivo" ]]; then
            procesar_archivo "$(basename "$archivo")"
        fi
    done
    if ((CONTADOR>=3)); then
      generar_backup
      CONTADOR=0
      echo "ENTRO AL BACKUP"
      
    fi
}

# Función para procesar un archivo nuevo
function procesar_archivo() {
    local archivo="$1"
    local extension="${archivo##*.}"
    extension_upper=$(echo "$extension" | tr '[:lower:]' '[:upper:]')
    destino="$DIRECTORIO/$extension_upper"
    mkdir -p "$destino"
    #mv "$DIRECTORIO/$archivo" "$destino/"
    mover_archivo "$DIRECTORIO/$archivo" "$destino"
    
    ((CONTADOR++))
    if ((bandera & CONTADOR >= CANTIDAD )); then      
        generar_backup
        CONTADOR=0
    fi
}

function mover_archivo() {
    archivo_origen="$1"
    directorio_destino="$2"

    # Verificación de existencia
    if [[ ! -f "$archivo_origen" ]]; then
        echo "Error: El archivo origen no existe."
        return 1
    fi

    if [[ ! -d "$directorio_destino" ]]; then
        echo "Error: El directorio destino no existe."
        return 1
    fi

    # Obtener nombre del archivo
    nombre_archivo=$(basename -- "$archivo_origen")
    nombre="${nombre_archivo%.*}"
    local extension="${nombre_archivo##*.}"

    # Manejar archivos sin extensión
    if [[ "$nombre" == "$extension" ]]; then
        extension=""
    else
        extension=".$extension"
    fi

    nuevo_nombre="$nombre$extension"
    contador=1

    # Evitar sobrescribir
    while [[ -e "$directorio_destino/$nuevo_nombre" ]]; do
        nuevo_nombre="${nombre}_$contador$extension"
        ((contador++))
    done

    # Mover el archivo
    mv "$archivo_origen" "$directorio_destino/$nuevo_nombre"
}

# Función para generar backup
function generar_backup() {
    fecha=$(date '+%Y%m%d_%H%M%S')
    nombre_backup="$(basename "$DIRECTORIO")_${fecha}.zip"
    zip -r "$DESTINO/$nombre_backup" "$DIRECTORIO" > /dev/null
    echo "Backup generado: $nombre_backup"
}

# ===========================
#          MAIN
# ===========================

# Parseo de argumentos
DIRECTORIO=""
DESTINO=""
CANTIDAD=""
KILL_MODE=0
DAEMON_MODE=0
HELP_MODE=0

CONTADOR=0


while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--directorio)
            if [[ -d "$2" ]]; then
                DIRECTORIO="$2"
                shift 2
                
            else
                echo "El directorio especificado en -d/--directorio NO es valido"
                exit 1
            fi            
		;;
        -s|--salida|--backup)
            if [[ -d "$2" ]]; then
                DESTINO="$2"
                shift 2
                
            else
                echo "El directorio especificado en -s/--salida NO es valido"
                exit 1
            fi            
		;;
        -c|--cantidad)
            if [[ "$2" =~ ^-?[0-9]+$ ]]; then
                CANTIDAD="$2"
                shift 2
                
            else
                echo "El valor especificado en -c /--cantidad NO es un numero"
                exit 1
            fi
            ;;

        -k|--kill)
            KILL_MODE=1
            shift
            ;;
        --daemon)
            DAEMON_MODE=1
            shift
            ;;
        -h|--help)
            HELP_MODE=1
            shift
            ;;
    esac
done
    
if ((HELP_MODE)); then
    mostrar_uso
fi

if (($KILL_MODE)); then
    if [[ -z "$DIRECTORIO" ]]; then
        echo "Necesita especificar el directorio asignado al script para matar"
        exit 1
    fi
    detener_demonio
fi

if [[ -z "$DIRECTORIO" || -z "$CANTIDAD" || -z "$DESTINO" ]]; then
    echo "Faltan elementos a especificar para ejecutar el script"
fi


if (( ! DAEMON_MODE )); then
    # Validar que no haya otro demonio para este directorio
    PID_FILE="$PID_DIR/$(basename "$DIRECTORIO").pid"
    if [[ -f "$PID_FILE" ]]; then
        PID=$(sed -n "1p" "$PID_FILE")
        echo " PID: $PID"
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "Ya existe un demonio corriendo para $DIRECTORIO (PID: $PID)"
            exit 1
        else
            echo "PID muerto encontrado, limpiando..."
            rm -f "$PID_FILE"
        fi
    fi

    lanzar_demonio -d "$DIRECTORIO" -s "$DESTINO" -c "$CANTIDAD"
    exit 0
fi

demonio