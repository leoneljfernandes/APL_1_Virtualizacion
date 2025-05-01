#!/bin/bash

function ayuda() {
    echo "Bienvenido al script contador de palabras."
    echo "Debe especificar los siguientes argumentos:"
    echo "  -i, --id        Id/s de las frutas a buscar."
    echo "  -n, --name      Nombre/s de las frutas a buscar."   
    echo "  -h, --help      Muestra esta ayuda."
}

API_URL="https://www.fruityvice.com/api/fruit"
CACHE_DIR="./cache"

# Crear el directorio de cache si no existe
mkdir -p "$CACHE_DIR"

# Inicializar variables
ids=()
names=()

options=$(getopt -o i:n:h --long help,id:,name: -- "$@" 2>&1)
if [[ $? -ne 0 ]]; then
    echo "Error: Opcion no reconocida."
    ayuda
    exit 1
fi
eval set -- "$options"

# Procesar argumentos
while true; do
    case "$1" in
        -i|--id)
            IFS=',' read -r -a ids <<< "$2"
            shift 2
            ;;
        -n|--name)
            IFS=',' read -r -a names <<< "$2"
            shift 2
            ;;
        -h|--help)
            ayuda
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Error: Opcion no reconocida."
            exit 1
            ;;
    esac
done


# Validar parametros
function validarParametros(){
    if [[ ${#ids[@]} -eq 0 && ${#names[@]} -eq 0 ]]; then
        echo "Debe especificar al menos --id o --name."
        exit 1
    fi
}

function imprimir_info() {
    local json="$1"

    id=$(echo "$json" | jq '.id')
    name=$(echo "$json" | jq -r '.name')
    genus=$(echo "$json" | jq -r '.genus')
    calories=$(echo "$json" | jq '.nutritions.calories')
    fat=$(echo "$json" | jq '.nutritions.fat')
    sugar=$(echo "$json" | jq '.nutritions.sugar')
    carbohydrates=$(echo "$json" | jq '.nutritions.carbohydrates')
    protein=$(echo "$json" | jq '.nutritions.protein')

    echo "id: $id,"
    echo "name: $name,"
    echo "genus: $genus,"
    echo "calories: $calories,"
    echo "fat: $fat,"
    echo "sugar: $sugar,"
    echo "carbohydrates: $carbohydrates,"
    echo "protein: $protein"
    echo
}

function buscar_id(){
    local id="$1"
    local cache_file="$CACHE_DIR/${id}.json"

    if [[ -f "$cache_file" ]]; then
        echo "Fruta encontrada en cache (id=$id)" >&2
        cat "$cache_file"
        return 0
    fi

    return 1
}

function buscar_name(){
    local name="$1"

    for archivo in "$CACHE_DIR"/*.json; do
        nombre=$(jq -r '.name' "$archivo" | tr '[:upper:]' '[:lower:]')

        if [[ "$nombre" == "$name" ]]; then
            echo "Fruta encontrada en cache (name=$name)" >&2
            cat "$archivo"
            return 0
        fi
    done

    return 1
}


function buscar_fruta(){
    local query="$1"
    local valor="$2"
    local resultado

    if [[ "$query" == "id" ]]; then
        if resultado=$(buscar_id "$valor"); then
            echo "$resultado"
            return 0
        fi
    fi

    if [[ "$query" == "name" ]]; then
        if resultado=$(buscar_name "$valor"); then
            echo "$resultado"
            return 0
        fi
    fi

    respuesta=$(curl -s -f "${API_URL}/${valor}")
    if [[ $? -ne 0 || -z "$respuesta" ]]; then
        echo "Error: No se encontró información para $query '$valor'." >&2
        return 1
    fi

    idFruta=$(echo "$respuesta" | jq -r '.id')
    echo "$respuesta" > "$CACHE_DIR/$idFruta.json"
    echo "$respuesta"
    return 0
}

validarParametros

# Procesar IDs
for id in "${ids[@]}"; do
    if json=$(buscar_fruta "id" "$id"); then
        imprimir_info "$json"
    fi
done

# Procesar Nombres
for name in "${names[@]}"; do
    name_clean=$(echo "$name" | tr '[:upper:]' '[:lower:]' | xargs)
    if json=$(buscar_fruta "name" "$name_clean"); then
        imprimir_info "$json"
    fi
done
