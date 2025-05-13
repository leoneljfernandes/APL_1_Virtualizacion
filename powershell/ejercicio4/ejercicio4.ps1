#!/usr/bin/env pwsh

# Integrantes del grupo:
# - Berti Rodrigo
# - Burnowicz Alejo
# - Fernandes Leonel
# - Federico Agustin

param(
    [string]$directorio,
    [string]$salida,
    [string]$cantidad,
    [switch]$kill,
    [switch]$daemon,
    [switch]$help
)

# Variables globales
$PID_DIR = "/tmp"
$SCRIPT_NAME = Split-Path -Leaf $MyInvocation.MyCommand.Path
$SELF_PATH = (Get-Item $MyInvocation.MyCommand.Path).FullName

# Función para mostrar uso
function Mostrar-Uso {
    Write-Output "Uso:"
    Write-Output "  .\$SCRIPT_NAME -directorio <directorio> -salida <salida_dir> -cantidad <cantidad>"
    Write-Output "  .\$SCRIPT_NAME -directorio <directorio> -kill"
    exit 0
}

# Función para lanzar el demonio en segundo plano
function Lanzar-Demonio {
    Start-Process -FilePath "pwsh" -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$SELF_PATH`" --daemon -directorio `"$directorio`" -salida `"$salida`" -cantidad $cantidad"
    Write-Output "Demonio lanzado para el directorio $directorio"
    exit 0
}

# Función para detener el demonio
function Detener-Demonio {
    $pidFile = Join-Path $PID_DIR ("$(Split-Path $directorio -Leaf).pid")
    if (Test-Path $pidFile) {
        $pidOriginal = Get-Content $pidFile
        try {
            Stop-Process -Id $pidOriginal -ErrorAction Stop
            Write-Output "Demonio detenido correctamente."
            Remove-Item $pidFile -Force
        } catch {
            Write-Output "No se pudo detener el demonio."
        }
    } else {
        Write-Output "No hay demonio corriendo para el directorio $directorio."
    }
    exit 0
}

# Función para ordenar archivos existentes
function Ordenar-Archivos {
    Get-ChildItem -Path $directorio -File | ForEach-Object {
        Procesar-Archivo $_.Name
    }
    if($script:contador -ge $cantidad) {
     Start-Sleep -Seconds 2
     Generar-Backup
     $script:contador=0
     }
}

# Función para procesar un archivo
function Procesar-Archivo($archivo) {
    $extension = ($archivo | Split-Path -Extension).TrimStart('.')
    $extensionUpper = $extension.ToUpper()
    $destino = Join-Path $directorio $extensionUpper
    if (-not (Test-Path $destino)) {
        New-Item -ItemType Directory -Path $destino | Out-Null
    }
    #Move-Item -Path (Join-Path $directorio $archivo) -Destination $destino
    Mover-archivo (Join-Path $directorio $archivo) $destino

    $script:contador++
    if ($bandera -eq 1 -and $script:contador -ge $cantidad) {
        Start-Sleep -Seconds 2
	Generar-Backup
        $script:contador = 0
    }
}

function Mover-archivo {
    param (
        [string]$archivo,
        [string]$destino
    )

    $nombreArchivo = Split-Path $archivo -Leaf
    $nombreBase = [System.IO.Path]::GetFileNameWithoutExtension($nombreArchivo)
    $extension = [System.IO.Path]::GetExtension($archivo)
    $nuevoNombre = $nombreArchivo
    $contador = 1

    while (Test-Path (Join-Path $destino $nuevoNombre)) {
        $nuevoNombre = "$nombreBase" + "_$contador$extension"
        $contador++
    }

    Move-Item -Path $archivo -Destination (Join-Path $destino $nuevoNombre)
}

# Función para generar backup
function Generar-Backup {
    $fecha = Get-Date -Format "yyyyMMdd_HHmmss"
    $nombresalida = "$(Split-Path $directorio -Leaf)_$fecha.zip"
    #Compress-Archive -Path (Join-Path $directorio '*') -DestinationPath (Join-Path $salida $nombresalida)
    zip -r "$salida/$nombresalida" "$directorio" > /dev/null
    Write-Output "Backup generado: $nombresalida"
}

# Función principal del demonio
function Demonio {
    $pidFile = Join-Path $PID_DIR ("$(Split-Path $directorio -Leaf).pid")
    $PID | Out-File $pidFile -Force

    $bandera=0

    Ordenar-Archivos

    $bandera=1

    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = (Resolve-Path $directorio).Path
    $watcher.IncludeSubdirectories = $false
    $watcher.EnableRaisingEvents = $true
    $watcher.Filter = '*'


    $global:procesadosRecientes = @{}

    Register-ObjectEvent $watcher Created -SourceIdentifier FileCreated -Action {
    	$nombreArchivo = $Event.SourceEventArgs.Name
    	$ahora = Get-Date

    	if ($global:procesadosRecientes[$nombreArchivo] -and ($ahora - $global:procesadosRecientes[$nombreArchivo]).TotalSeconds -lt 5) {
        	return  # Ya fue procesado recientemente
    	}

    	$global:procesadosRecientes[$nombreArchivo] = $ahora
    	Start-Sleep -Milliseconds 1000
    	Procesar-Archivo $nombreArchivo
	}

    Register-ObjectEvent $watcher Changed -SourceIdentifier FileChanged -Action {
    	$nombreArchivo = $Event.SourceEventArgs.Name
    	$ahora = Get-Date

    	if ($global:procesadosRecientes[$nombreArchivo] -and ($ahora - $global:procesadosRecientes[$nombreArchivo]).TotalSeconds -lt 5) {
        	return  # Ya fue procesado recientemente
    	}

    	$global:procesadosRecientes[$nombreArchivo] = $ahora
    	Start-Sleep -Milliseconds 1000
    	Procesar-Archivo $nombreArchivo
	}

    while ($true) {
        Start-Sleep -Seconds 4
    }
}

# ===========================
#          MAIN
# ===========================

# Validaciones
if ($help) {
    Mostrar-Uso
}


if ($kill) {
    if (-not $directorio) {
        Write-Output "Necesita especificar el directorio asignado al script para matar"
        exit 1
    }
    Detener-Demonio
}

if (-not $directorio -or -not $cantidad -or -not $salida) {
    Write-Output "Faltan elementos a especificar para ejecutar el script"
    exit 1
}

if (-not [int]::TryParse($cantidad, [ref]$null)) {
    Write-Output "El valor especificado en -cantidad NO es un numero"
    exit 1
}

$cantidad = [int] $cantidad

if(-not (Test-Path $directorio -PathType Container)){
    Write-Output "El directorio especificado en -directorio NO es valido"
    exit 1
}

if(-not (Test-Path $salida -PathType Container)){
    Write-Output "El directorio especificado en -salida NO es valido"
    exit 1
}

# Verificar si ya hay demonio corriendo
$pidFile = Join-Path $PID_DIR ("$(Split-Path $directorio -Leaf).pid")
if (-not $daemon) {
    if (Test-Path $pidFile) {
        $pidOriginal = Get-Content $pidFile
        if (Get-Process -Id $pidOriginal -ErrorAction SilentlyContinue) {
            Write-Output "Ya existe un demonio corriendo para $directorio (PID: $pidOriginal)"
            exit 1
        } else {
            Write-Output "PID muerto encontrado, limpiando..."
            Remove-Item $pidFile -Force
        }
    }
    Lanzar-Demonio
}

# Si llegamos aquí, estamos en modo demonio
$script:contador = 0
Demonio