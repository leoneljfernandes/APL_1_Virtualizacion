Param (
    [Parameter(Mandatory=$false)]
    [string]$Matriz,
    [Parameter(ParameterSetName='Producto',Mandatory=$false)]
    [double]$Producto,
    [switch]$Trasponer,
    [Parameter(Mandatory=$false)]
    [string]$Separador,
    [switch]$Help
)

function Get-Ayuda {
    Write-Host "Bienvenido al script de procesamiento de Matrices."
    Write-Host "El mismo realizara el producto escalar y la transposicion de la matriz."
    Write-Host "Puede optar por las siguientes opciones:"
    Write-Host "  -Matriz  <directorio>      Especifica el directorio del archivo de la matriz."
    Write-Host "  -Producto                  Valor entero para utilizarse en el producto escalar."   
    Write-Host "  -Trasponer                 Indica que se debe realizar la operación de trasposición sobre la matriz. (no recibe valor adicional, solo el parámetro)."
    Write-Host "  -Separador                 Carácter para utilizarse como separador de columnas.."
    Write-Host "  -Help                      Muestra esta ayuda."
}

if ($Help) {
    Get-Ayuda
    exit
}

#Validaciones

if (-not $Producto -and -not $Trasponer) {
    Write-Host "Error: Debe especificar al menos un argumento de salida."
    Get-Ayuda
    exit
}
if ($Producto -and $Trasponer) {
    Write-Host "Error: No puede especificar tanto -Producto como -Trasponer."
    Get-Ayuda
    exit
}

# Validar que el parámetro de archivo de entrada no esté vacío
if ([string]::IsNullOrEmpty($Matriz)) {
    Write-Host "Error: Debe especificar un archivo de entrada."
    exit 1
}

# Verificar si el archivo existe
if (-not (Test-Path -Path $Matriz)) {
    Write-Host "Error: El archivo $Matriz no existe."
    exit 1
}

# Valdamos que el directorio tenga permisos de lectura
if (-not (Test-Path -Path $Directorio -PathType Container)){
    Write-Host "Error: No se tienen permisos de lectura en el directorio $Directorio."
    exit 1
}

# Verificar si se tienen permisos de lectura en el archivo
try {
    [System.IO.File]::OpenRead($Matriz).Close()
} catch [UnauthorizedAccessException] {
    Write-Host "Error: No se tienen permisos de lectura en el archivo $Matriz."
    exit 1
} catch {
    Write-Host "Error: No se puede acceder al archivo $Matriz."
    exit 1
}

# Validar que el archivo de entrada no esté vacío
if ((Get-Item $Matriz).Length -eq 0) {
    Write-Host "Error: El archivo $Matriz está vacío."
    exit 1
}

#Valido que el separador se halla pasado
if ([string]::IsNullOrEmpty($Separador)) {
    Write-Host "Error: El separador no puede estar vacío."
    exit 1
}

#Valido que el separador sea solo un caracter
if ($Separador.Length -ne 1){
    Write-Host "Error: El separador debe ser solo un caracter."
    exit 1
}

#Validamos que el separador no sea nros o "-"
if($Separador -match '^[0-9]$' -or $Separador -eq "-"){
    Write-Host "Error: El separador no puede ser un número o un signo negativo."
    exit 1
}

#Validamos que la matriz sea valida
#Debe poseer igual cantidad de columnas en todas las filas
#Deben ser nros, positivos o negativos o decimales, no se permite texto

$matrizC = @()
$primerLength = $null


Get-Content -Path $Matriz -ErrorAction Stop | ForEach-Object {
    $elementos = $_.Split($Separador, [System.StringSplitOptions]::RemoveEmptyEntries)
    
    # Validar valores numéricos
    $fila = @()
    foreach ($elemento in $elementos) {
        if ($elemento -match '^[+-]?\d+(\.\d+)?$') {
            $fila += [double]$elemento
        } else {
            Write-Host "Error: Valor no numérico encontrado '$elemento'"
            exit 1
        }
    }

    # Validar número de columnas
    if ($null -eq $primerLength) {
        $primerLength = $fila.Length
    } elseif ($fila.Length -ne $primerLength) {
        Write-Host "Error: La fila tiene $($fila.Length) columnas, se esperaban $primerLength"
        exit 1
    }
    
    $matrizC += ,$fila
}

#Procesamos la matriz
if ($Producto){
    for($i = 0; $i -lt $matrizC.Count; $i++) {
        for($j = 0; $j -lt $matrizC[$i].Count; $j++) {
            $matrizC[$i][$j] *= $Producto
        }
    }
    Write-Host "Matriz después de multiplicar por $Producto :"
    $matrizC | ForEach-Object { $_ -join " " }

    #Grabo la salida en un archivo
    $carpeta = $Matriz.substring(0, $Matriz.LastIndexOf('/'))
    $nombre = $Matriz.substring($Matriz.LastIndexOf('/') + 1)
    $nombreArchivoSalida = "$carpeta/salida$nombre"
    Write-Host "Nombre del archivo de salida: $nombreArchivoSalida"
    try {
        $matrizC | ForEach-Object { $_ -join " " } | Out-File -FilePath $nombreArchivoSalida -Encoding utf8 -ErrorAction Stop
        Write-Host "`nResultado guardado en: $outputFile"
    } catch {
        Write-Host "Error al guardar el archivo: $_"
        exit 1
    }
}

if($Trasponer){
    $matrizT = @()
    for($i = 0; $i -lt $matrizC[0].Count; $i++) {
        $filaT = @()
        for($j = 0; $j -lt $matrizC.Count; $j++) {
            $filaT += $matrizC[$j][$i]
        }
        $matrizT += ,$filaT
    }
    Write-Host "Matriz transpuesta:"
    $matrizT | ForEach-Object { $_ -join " " }

    #Grabo la salida en un archivo
    $carpeta = $Matriz.substring(0, $Matriz.LastIndexOf('/'))
    $nombre = $Matriz.substring($Matriz.LastIndexOf('/') + 1)
    $nombreArchivoSalida = "$carpeta/salida$nombre"
    Write-Host "Nombre del archivo de salida: $nombreArchivoSalida"
    try {
        $matrizT | ForEach-Object { $_ -join " " } | Out-File -FilePath $nombreArchivoSalida -Encoding utf8 -ErrorAction Stop
        Write-Host "`nResultado guardado en: $outputFile"
    } catch {
        Write-Host "Error al guardar el archivo: $_"
        exit 1
    }
}






