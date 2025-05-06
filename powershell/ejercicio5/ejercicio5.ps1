<#
.SYNOPSIS
    Consulta la API de Fruityvice para obtener información sobre frutas.

.DESCRIPTION
    Este script permite consultar la API de Fruityvice para obtener información sobre frutas.:
    - Id/s de las frutas a buscar.
    - Name de las frutas a buscar.
    Se puede especificar uno o más Ids o nombres de frutas  en simultaneo
.PARAMETER Id
    Id's de frutas

.PARAMETER Name
    Nombre de la fruta, en ingles
.PARAMETER Help
    Muestra este mensaje de ayuda.

.EXAMPLE
    .\ejercicio5.ps1 -Id 11,22 -Name "banana,apple"

.NOTES
#>

[CmdletBinding(DefaultParameterSetName='Parametros')]
Param (
    [int[]]$Id,
    [string[]]$Name,
    [switch]$Help
)

function Get-Ayuda {
    Write-Host "Bienvenido al script de consulta a la API Fruityvice."
    Write-Host "Debe especificar los siguientes argumentos."
    Write-Host "  -Id          Id/s de las frutas a buscar."
    Write-Host "  -Name        Nombre/s de las frutas a buscar."   
    Write-Host "  -Help        Muestra esta ayuda."
}

$API_URL="https://www.fruityvice.com/api/fruit"
$CACHE_DIR="./cache"
$CACHE_TTL = 3600 # 1 hora

if ( -not (Test-Path -Path $CACHE_DIR)){
    New-Item -ItemType Directory -Path $CACHE_DIR
}

function validarParametros(){
    if (-not $Id -and -not $Name){
        Write-Host "Error: Debe especificar al menos un -Id o -Name."
        Get-Ayuda
        exit 1
    }

    for ($i=0; $i -lt $Id.Count; $i++){
        if (-not ($Id[$i] -is [int])){
            Write-Host "Error: El Id $($Id[$i]) no es un número entero."
            exit 1
        }
    }

    for ($i=0; $i -lt $Name.Count; $i++){
        if ( -not ($Name[$i] -is [string] )) {
            Write-Host "Error: El nombre $($Name[$i]) no es una cadena de texto."
            exit 1
        }
    }
}

function cache_valido(){
    param(
        [string]$archivoCache
    )
    if (-not (Test-Path -Path $archivoCache)){
        return $false
    }
    $modTime = (Get-Item $archivoCache).LastWriteTime
    $ahora = [DateTime]::UtcNow
    $diferenciaTiempo = ($ahora - $modTime).TotalSeconds

    if ($diferenciaTiempo -gt $CACHE_TTL){
        return $false #cache expirado
    }
    return $true
}

function buscarFruta(){
    Param(
        [ValidateSet("id", "name")]
        [string]$query, 
        $valor
    )

    $jsonFruta = $null

    switch ($query){
        "id" {            
            # Verifico si la fruta ya fue consultada y es valida la cache
            if (cache_valido -archivoCache (Join-Path -Path $CACHE_DIR -ChildPath "$valor.json")){
                Write-Host "La fruta con id $valor ya fue consultada."
                $fullPathFruta = Join-Path -Path $CACHE_DIR -ChildPath "$valor.json"
                $jsonFruta = Get-Content -Path $fullPathFruta | ConvertFrom-Json 
                Write-Host ($jsonFruta | ConvertTo-Json -Depth 10)
                return
            }

            #Si no fue consultada, la busco en la API
            $url = "$API_URL/$valor"
            Write-Host "Consultando la API para el id $valor..."

            try{
                $response = Invoke-WebRequest -Uri $url -Method Get
            }catch{
                #guardar el mensaje de error en un archivo
                $errorMessage = $_.Exception.Message
                $errorFile = Join-Path -Path $CACHE_DIR -ChildPath "error.log"
                $errorMessage | Out-File -FilePath $errorFile -Append
                Write-Host "Error: No se encontro la fruta con nombre $valor."
                return
            }

            $jsonFruta = $response.Content | ConvertFrom-Json
            $idFruta = $jsonFruta.id
            
            $cacheFile = Join-Path -Path $CACHE_DIR -ChildPath "$idFruta.json"

            # Guardar el JSON en el archivo
            $jsonFruta | ConvertTo-Json -Depth 10 | Set-Content -Path $cacheFile -Encoding UTF8

            #Imprimo en pantalla el json
            Write-Host ($jsonFruta | ConvertTo-Json -Depth 10)
            return
        }
        "name" {

            # Verifico si la fruta ya fue consultada buscando en frutasConsultadas
            # Por el nombre
            $archivosJson = Get-ChildItem -Path $CACHE_DIR -Filter "*.json"

            foreach ($archivo in $archivosJson){

                $contenidoJson = Get-Content -Path $archivo.FullName | ConvertFrom-Json

                if ($contenidoJson.name -eq $valor -and (cache_valido -archivoCache $archivo.FullName)){
                    Write-Host "La fruta con nombre $valor ya fue consultada."
                    $pathFruta = $contenidoJson.id.ToString() + ".json"
                    $fullPathFruta = Join-Path -Path $CACHE_DIR -ChildPath $pathFruta
                    $jsonFruta = Get-Content -Path $fullPathFruta | ConvertFrom-Json 
                    Write-Host ($jsonFruta | ConvertTo-Json -Depth 10)
                    return  
                }
            }

            #Si no fue consultada, la busco en la API
            $url = "$API_URL/$valor"
            Write-Host "Consultando la API para el id $valor..."
            try{
                $response = Invoke-WebRequest -Uri $url -Method Get
            }catch{
                #guardar el mensaje de error en un archivo
                $errorMessage = $_.Exception.Message
                $errorFile = Join-Path -Path $CACHE_DIR -ChildPath "error.log"
                $errorMessage | Out-File -FilePath $errorFile -Append
                Write-Host "Error: No se encontro la fruta con nombre $valor."
                return
            }
            
            $jsonFruta = $response.Content | ConvertFrom-Json
            $idFruta = $jsonFruta.id

            $cacheFile = Join-Path -Path $CACHE_DIR -ChildPath "$idFruta.json"

            # Guardar el JSON en el archivo
            $jsonFruta | ConvertTo-Json -Depth 10 | Set-Content -Path $cacheFile -Encoding UTF8

            #Imprimo en pantalla el json
            Write-Host ($jsonFruta | ConvertTo-Json -Depth 10)
            return

        }
    }
}

function procesarParametros(){
    #Recorremos los ids
    foreach ($id in $Id){
        buscarFruta -query "id" -valor $id
    }

    #Recorremos los nombres
    foreach ($name in $Name){
        buscarFruta -query "name" -valor $name
    }
}

#Validar Parametros
validarParametros

#Procesamos los ids y nombres
procesarParametros

