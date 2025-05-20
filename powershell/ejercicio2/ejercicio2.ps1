#!/bin/pwsh
# Integrantes del grupo:
# - Berti Rodrigo
# - Burnowicz Alejo
# - Fernandes Leonel
# - Federico Agustin

<#
.SYNOPSIS
    Procesa matrices realizando producto escalar y/o transposición.

.DESCRIPTION
    Este script permite cargar una matriz desde un archivo y realizar operaciones como:
    - Producto escalar (multiplicar la matriz por un valor numérico)
    - Transposición de la matriz
    La matriz debe estar en un archivo de texto con valores separados por un delimitador.

.PARAMETER Matriz
    Ruta del archivo que contiene la matriz a procesar.

.PARAMETER Producto
    Valor numérico para realizar el producto escalar de la matriz.

.PARAMETER Trasponer
    Si se especifica, se transpondrá la matriz (intercambiar filas por columnas).

.PARAMETER Separador
    Carácter que se utiliza como separador de columnas en el archivo de matriz.

.PARAMETER Help
    Muestra este mensaje de ayuda.

.EXAMPLE
    .\ejercicio2.ps1 -Matriz "Directorio/entradaMatriz.in" -Producto 2
    Multiplica todos los elementos de la matriz por 2.

.EXAMPLE
    .\ejercicio2.ps1 -Matriz "Directorio/entradaMatriz.in" -Separador "," -Trasponer
    Transpone la matriz del archivo usando coma como separador.

.NOTES
#>

[CmdletBinding(DefaultParameterSetName='Parametros')]
Param (
    [Parameter(Mandatory=$true, HelpMessage="Ruta de la matriz de entrada", ParameterSetName='Parametros')]
    [string]$Matriz,
    [Parameter(Mandatory=$false, HelpMessage="Valor para el producto escalar", ParameterSetName='Parametros')]
    [int]$Producto,
    [Parameter (Mandatory=$false, HelpMessage="Realiza la transposición de la matriz", ParameterSetName='Parametros')]
    [switch]$Trasponer,
    [Parameter(Mandatory=$true, HelpMessage="Separador de columnas", ParameterSetName='Parametros')]
    [string]$Separador,
    [Parameter(Mandatory=$false, ParameterSetName='Ayuda', HelpMessage="Mas info de ayuda")]
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
    exit 1
}


function validacionesDeParametros{
    if (-not $Producto -and (-not $Trasponer)) {
        Write-Host "Error: Debe especificar al menos un argumento de salida."
        exit
    }
    if ($Producto -and $Trasponer) {
        Write-Host "Error: No puede especificar tanto -Producto como -Trasponer."
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
    if (-not (Test-Path -Path $Matriz -PathType Leaf)) {
        Write-Host "Error: La ruta especificada no existe o no es un archivo válido: $Matriz"
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
        Write-Host "Error: El separador no puede ser un número o un signo "-"."
        exit 1
    }
}

function validarArchivoMatriz {
    # Verificar si se pueden leer los contenidos
    try {
        $null = Get-Content -Path $Matriz -ErrorAction Stop
    } catch {
        Write-Host "Error: No se puede leer el archivo $Matriz. Detalles: $_"
        exit 1
    }

    # Validar que el archivo no esté vacío
    if ((Get-Item $Matriz).Length -eq 0) {
        Write-Host "Error: El archivo $Matriz está vacío."
        exit 1
    }
}

function validarMatriz (){
    param($matrizC)
    $primerLength = $null

    Get-Content -Path $Matriz -ErrorAction Stop | ForEach-Object {

        #Intento separar la matriz por el separador
        #Si no se puede separar, salgo
        try{
            $elementos = $_.Split($Separador, [System.StringSplitOptions]::RemoveEmptyEntries)
            if($elementos.Count -eq 1 -and $_.Contains($Separador) -eq $false -and $_.Trim() -ne "") {
                Write-Host "Error: No se pudo separar la fila '$_' usando el separador '$Separador'."
                exit 1
            }
        }catch {
            Write-Host "Error: No se pudo separar la fila '$_' usando el separador '$Separador'."
            exit 1
        }             
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
    return $matrizC
}
# Validamos los parametros
validacionesDeParametros

# Validamos el archivo matriz
validarArchivoMatriz

#Validamos que la matriz sea valida
#Debe poseer igual cantidad de columnas en todas las filas
#Deben ser nros, positivos o negativos o decimales, no se permite texto
$matrizC = @()
$matrizC = validarMatriz -matriz $matrizC

#Procesamos la matriz
if ($Producto -and -not $Trasponer) {
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
        Write-Host "`nResultado guardado en: $nombreArchivoSalida"
    } catch {
        Write-Host "Error al guardar el archivo: $_"
        exit 1
    }
}

if($Trasponer -and -not $Producto){
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
        Write-Host "`nResultado guardado en: $nombreArchivoSalida"
    } catch {
        Write-Host "Error al guardar el archivo: $_"
        exit 1
    }
}






