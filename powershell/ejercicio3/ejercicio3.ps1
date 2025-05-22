
#!/bin/pwsh
# Integrantes del grupo:
# - Berti Rodrigo
# - Burnowicz Alejo
# - Fernandes Leonel
# - Federico Agustin

<#
.SYNOPSIS
Muestra información sobre cómo usar el script contador de palabras.

.DESCRIPTION
Este script analiza archivos de texto dentro de un directorio especificado y cuenta la aparición de palabras específicas.

.PARAMETER Directorio
Especifica el directorio donde se encuentran los textos a analizar.

.PARAMETER Palabras
Lista de palabras a contar, separadas por comas.

.PARAMETER Archivos
Lista de extensiones de archivos a buscar, separadas por comas.

.PARAMETER Help
Muestra esta ayuda.

.EXAMPLE
.\ejercicio3.ps1 -Directorio "C:\MisArchivos" -Palabras "palabra1,palabra2" -Archivos "txt,log"

Muestra la ayuda del script con una descripción de los parámetros requeridos.
#>

[CmdletBinding(DefaultParameterSetName='Parametros')]
param(
    [Parameter(Mandatory=$true, HelpMessage="Ruta del directorio a analizar", ParameterSetName='Parametros')]
    [string]$directorio,
    [Parameter(Mandatory=$true, HelpMessage="Lista de palabras a contabilizar", ParameterSetName='Parametros')]
    [string[]]$palabras,
    [Parameter(Mandatory=$true, HelpMessage="Lista de extensiones de archivos a buscar.", ParameterSetName='Parametros')]
    [string[]]$archivos,
    [Parameter(Mandatory=$false, ParameterSetName='Ayuda', HelpMessage="Mas info de ayuda")]
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

function validacionDeParametros{

    if ($Help) {
        Get-Ayuda
        exit 1
    }

    if (-not $directorio){
        Write-Host "Error: Debe especificar un directorio."
        exit 1
    }
    if (-not $palabras){
        Write-Host "Error: Debe especificar al menos una palaba a buscar."
        exit 1
    }
    if(-not $archivos){
        Write-Host "Error: Debe especificar al menos una extension de archivo a buscar."
        exit 1
    }

    # Validamos que el directorio exista
    if (-not (Test-Path -Path $directorio)){
        Write-Host "Error: El directorio $directorio no existe."
        exit 1
    }

    # Validamos que el directorio tenga permisos de lectura
    if (-not (Test-Path -Path $directorio -PathType Container)){
        Write-Host "Error: No se tienen permisos de lectura en el directorio $directorio."
        exit 1
    }
}

validacionDeParametros


# Validación para asegurar que el parametro archivos llego como array 
if ($archivos.Count -eq 1 -and $archivos[0] -like "*,*") {
    $archivos = $archivos[0] -split "," | ForEach-Object { $_.Trim() }
}

#Validación para concatenar el punto y el * que indica todo lo que esta atras
$ExtensionTypes = $archivos | ForEach-Object { "*." + $_}

#Validación para asegurar que el parametro palabras llego como array porque anda raro
if ($palabras.Count -eq 1 -and $palabras[0] -like "*,*") {
    $palabras = $palabras[0] -split "," | ForEach-Object { $_.Trim() }
}

$ObjArr = Get-ChildItem -Path $directorio -Include $ExtensionTypes -Recurse -ErrorAction SilentlyContinue -Force

#notar el parametro -Raw para que TextContainer no sea un Object[] y sea un string entero para que funcione bien Select-String
$TextContainer = $ObjArr | ForEach-Object { Get-Content $_ -Raw }

foreach ($palabra in $palabras) {
    $matches = Select-String -InputObject $TextContainer -Pattern $palabra -AllMatches -CaseSensitive
    $conteo = ($matches.Matches).Count
    Write-Output "$palabra : $conteo"
}
