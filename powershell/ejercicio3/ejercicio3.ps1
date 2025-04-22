Param (
    [Parameter(Mandatory=$true, ParameterSetName='Busqueda')]
    [string]$Directorio,

    [Parameter(Mandatory=$true, ParameterSetName='Busqueda')]
    [string]$Palabras,

    [Parameter(Mandatory=$true, ParameterSetName='Busqueda')]
    [string]$Archivos,

    [Parameter(Mandatory=$false, ParameterSetName='Ayuda')]
    [switch]$Help
)

function Get-Ayuda {
    Write-Host "Bienvenido al script contador de palabras."
    Write-Host "Debe especificar los siguientes argumentos:"
    Write-Host " -Directorio <directorio>   Especifica el directorio donde se contengan textos a analizar."
    Write-Host " -Palabras                  Lista de palabras a contar separadas por comas."   
    Write-Host " -Archivos                  Lista de extensiones de archivos a buscar separadas por comas."
    Write-Host " -Help                      Muestra esta ayuda."
}

if ($Help) {
    Get-Ayuda
    exit
}

# Validaciones
#Valido que se hayan pasadoso los argumentos necesarios
if (-not $Directorio){
    Write-Host "Error: Debe especificar un directorio."
    exit 1
}
if (-not $Palabras){
    Write-Host "Error: Debe especificar al menos una palaba a buscar."
    exit 1
}
if(-not $Archivos){
    Write-Host "Error: Debe especificar al menos una extension de archivo a buscar."
    exit 1
}

# Validamos que el directorio exista
if (-not (Test-Path -Path $Directorio)){
    Write-Host "Error: El directorio $Directorio no existe."
    exit 1
}

# Validamos que el directorio tenga permisos de lectura
if (-not (Test-Path -Path $Directorio -PathType Container)){
    Write-Host "Error: No se tienen permisos de lectura en el directorio $Directorio."
    exit 1
}

# Obtengo todos los archivos con extension especificada en $Archivos
$archivosEncontrados  = @()
foreach ($ext in $Archivos.Split(',')){
    $archivosEncontrados  += Get-ChildItem -Path $Directorio -Filter "*.$ext" -Recurse
}

#debug de los archivos existentes
#foreach ($arch in $archivosEncontrados ){
#    Write-Host "Archivo encontrado: $($arch.FullName)"
#}

# Valido que se hayan encontrado archivos
if ($archivosEncontrados.Count -eq 0){
    Write-Host "Error: No se encontraron archivos en el directorio $Directorio con las extensiones especificadas."
    exit 1
}

# Guardo las palabras buscadas en un array para contar la cantidad de veces que aparecen
$conteoPalabras = @{}
foreach ($palabra in $Palabras.Split(',')){
    $conteoPalabras[$palabra] = 0
}

# Procesar archivos
foreach ($arch in $archivosEncontrados) {
    Write-Host "Procesando archivo: $($arch.FullName)"
    
    try {
        # Verificar permisos de lectura
        $stream = $null
        try {
            $stream = [System.IO.File]::OpenRead($arch.FullName)
        }
        finally {
            if ($null -ne $stream) {
                $stream.Close()
            }
        }

        # Verificar si el archivo está vacío
        if ($arch.Length -eq 0) {
            Write-Host "Advertencia: El archivo $($arch.Name) está vacío."
            continue
        }

        # Leer contenido
        $contenido = Get-Content -Path $arch.FullName -Raw -ErrorAction Stop

        # Contar palabras
        foreach ($palabra in $conteoPalabras.Keys) {
            $aciertos = [regex]::Matches($contenido, "\b$([regex]::Escape($palabra))\b", 'IgnoreCase')
            $conteoPalabras[$palabra] += $aciertos.Count
        }
    }
    catch [UnauthorizedAccessException] {
        Write-Host "Error: No se tienen permisos para leer el archivo $($arch.Name)"
        continue
    }
    catch {
        Write-Host "Error al procesar $($arch.Name): $_"
        continue
    }
}

# Mostrar resultados
Write-Host "`nResultados finales:"
$conteoPalabras.GetEnumerator() | Sort-Object -Property Value -Descending | ForEach-Object {
    Write-Host "$($_.Key): $($_.Value)"
}



