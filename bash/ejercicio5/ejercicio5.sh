#!/bin/bash

API_URL="https://www.fruityvice.com/api/fruit"
CACHE_DIR="./cache"

# Crear el directorio de cache si no existe
mkdir -p "$CACHE_DIR"

# Inicializar variables
ids=()
names=()

# Función para mostrar error y salir
function salida_error() {
    echo "$1" >&2
    exit 1
}

# Procesar argumentos
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--id)
            IFS=',' read -r -a ids <<< "$2"
            shift 2
            ;;
        -n|--name)
            IFS=',' read -r -a names <<< "$2"
            shift 2
            ;;
        *)
            salida_error "Parámetro no reconocido: $1"
            ;;
    esac
done

# Función para consultar fruta
busca_fruta() {
    local tipo="$1"
    local value="$2"
    local archivos_cache="$CACHE_DIR/${tipo}_${value}.json"

    if [[ -f "$cache_file" ]]; then
        cat "$cache_file"
    else
        respuesta=$(curl -s -f "${API_URL}/${value}")
        if [[ $? -ne 0 || -z "$respuesta" ]]; then
            echo "Error: No se encontró información para $tipo '$value'."
            return 1
        fi
        echo "$respuesta" > "$archivos_cache"
        echo "$respuesta"
    fi
}

# Función para imprimir información
imprimir_info() {
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

# Validar que haya al menos un parámetro
if [[ ${#ids[@]} -eq 0 && ${#names[@]} -eq 0 ]]; then
    error_exit "Debe especificar al menos --id o --name."
fi

# Procesar IDs
for id in "${ids[@]}"; do
    json=$(busca_fruta "id" "$id")
    if [[ $? -eq 0 ]]; then
        imprimir_info "$json"
    fi
done

# Procesar Nombres
for name in "${names[@]}"; do
    name_clean=$(echo "$name" | tr '[:upper:]' '[:lower:]' | xargs)
    json=$(busca_fruta "name" "$name_clean")
    if [[ $? -eq 0 ]]; then
        imprimir_info "$json"
    fi
done