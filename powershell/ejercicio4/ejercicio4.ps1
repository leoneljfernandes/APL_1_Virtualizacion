#!/usr/bin/env pwsh

# Integrantes del grupo:
# - Berti Rodrigo
# - Burnowicz Alejo
# - Fernandes Leonel
# - Federico Agustin

<#
.SYNOPSIS
Organiza archivos por extensión y realiza backups automáticos.

.DESCRIPTION
Este script actúa como un daemon que monitorea un directorio,
mueve archivos según su extensión a subdirectorios correspondientes,
y realiza backups en formato ZIP cada cierta cantidad de archivos procesados.

.PARAMETER directorio
Ruta del directorio que se va a monitorear.

.PARAMETER salida
Ruta donde se guardaran los backups del directorio.

.PARAMETER cantidad
Número de archivos procesados tras el cual se genera un backup ZIP.
Si bien este comando muestra que es de tipo STRING, esto es solamente para verificar que el valor ingresado sea un NUMERO de forma correcta

.PARAMETER kill
Bandera utilizada para detener una instancia de este script;debe ir acompañado del parametro directorio con su llamado correspondiente.

.PARAMETER help
Bandera utilizada para mostrar mas informacion

.EXAMPLE
./ejercicio4.ps1 -directorio "./Directorio" -salida "./Backup" -cantidad 20
./ejercicio4.ps1 -directorio "./Directorio" -kill"

#>


param(
    [Parameter(Mandatory=$true, ParameterSetName="OperacionNormal")]
    [Parameter(Mandatory=$true, ParameterSetName="TerminarOperacion")]
    [string]$directorio,
    [Parameter(Mandatory=$true, ParameterSetName="OperacionNormal")]
    [Parameter(Mandatory=$false, ParameterSetName="TerminarOperacion")]
    [string]$salida,
    [Parameter(Mandatory=$true, ParameterSetName="OperacionNormal")]
    [Parameter(Mandatory=$false, ParameterSetName="TerminarOperacion")]
    [string]$cantidad,
    [Parameter(Mandatory=$true, ParameterSetName="TerminarOperacion")]
    [switch]$kill,
    [Parameter(Mandatory=$false, ParameterSetName="OperacionNormal")]
    [switch]$daemon,
    [Parameter(Mandatory=$false, ParameterSetName="OperacionNormal")]
    [Parameter(Mandatory=$false, ParameterSetName="TerminarOperacion")]
    [switch]$help
)
# Variables globales
$PID_DIR = "/tmp"
$SCRIPT_NAME = Split-Path -Leaf $MyInvocation.MyCommand.Path
$SELF_PATH = (Get-Item $MyInvocation.MyCommand.Path).FullName



# Función para mostrar uso
function Mostrar-Uso {
    Write-Host "Bienvenido al script de monitoreo de directorios."
    Write-Host "El mismo se encargara de reorganizar los archivos sueltos en un directorio espefico en carpetas en base a sus extenciones."
    Write-Host "Ademas, tras un numero de archivos movidos especificado por el usuario, se generara un backup en forma de zip en un directorio espeficiado"
    Write-Host "Al ser un proceso DEMONIO, este debe ser detenido utilizando la opcion kill que se le especificara mas adelante (ademas de requerir que se especifique el directorio)"
    Write-Host "Puede optar por las siguientes opciones:"
    Write-Host "  -directorio  <Directorio>      Especifica el directorio que sera supervisado."
    Write-Host "  -salida <Directorio>           Especifica el directorio donde se realizara el backup correspondiente"   
    Write-Host "  -cantidad <Numero entero>      Cantidad de archivos necesarios para generar un backup"
    Write-Host "  -kill                          Bandera indicando que un proceso ejercicio4.ps1 debe ser terminado"
    Write-Host "  -help                          Muestra esta ayuda."
    Write-Host "Ejemplo:                         ./ejercicio4.ps1 -directorio './Directorio' -salida './Backup' -cantidad 20"
    Write-Host "Ejemplo:                         ./ejercicio4.ps1 -directorio './Directorio' -kill"
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
        }
        catch {
            Write-Output "No se pudo detener el demonio."
        }
    }
    else {
        Write-Output "No hay demonio corriendo para el directorio $directorio."
    }
    exit 0
}

# Función para ordenar archivos existentes
function Ordenar-Archivos {
    Get-ChildItem -Path $directorio -File | ForEach-Object {
        Procesar-Archivo $_.FullName
    }
    if ($script:contador -ge $cantidad) {
        Start-Sleep -Seconds 2
        Generar-Backup
        $script:contador = 0
    }
}

# Función para procesar un archivo
function Procesar-Archivo($rutaArchivo) {
    $extension = ([System.IO.Path]::GetExtension($rutaArchivo)).TrimStart('.')
    $extensionUpper = $extension.ToUpper()
    $destino = Join-Path $directorio $extensionUpper

    $extensionRutaProcesar = [System.IO.Path]::GetExtension($rutaArchivo)
    if ([string]::IsNullOrEmpty($extensionRutaProcesar)) {
        return
    }
    if (-not (Test-Path $destino)) {
        New-Item -ItemType Directory -Path $destino | Out-Null
    }
    Mover-Archivo $rutaArchivo $destino

    $script:contador++
    if ($bandera -eq 1 -and $script:contador -ge $cantidad) {
        Start-Sleep -Seconds 2
        Generar-Backup
        $script:contador = 0
    }
}

function Mover-Archivo {
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
    zip -r "$salida/$nombresalida" "$directorio" > /dev/null
    Write-Output "Backup generado: $nombresalida"
}

# Función principal del demonio
function Demonio {
    $pidFile = Join-Path $PID_DIR ("$(Split-Path $directorio -Leaf).pid")
    $PID | Out-File $pidFile -Force

    $bandera = 0
    Ordenar-Archivos
    $bandera = 1

    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = (Resolve-Path $directorio).Path
    $watcher.IncludeSubdirectories = $false
    $watcher.EnableRaisingEvents = $true
    $watcher.Filter = '*'

    $global:procesadosRecientes = @{}

    
    Register-ObjectEvent $watcher Created -SourceIdentifier FileCreated -Action {
        
        $rutaCompleta = $Event.SourceEventArgs.FullPath
        $ahora = Get-Date
        

        # Verifica si el archivo aún existe en el directorio original
        if (-not (Test-Path $rutaCompleta)) {
            return
        }
        
        # Verifica si ya fue procesado recientemente
        if ($global:procesadosRecientes[$rutaCompleta] -and ($ahora - $global:procesadosRecientes[$rutaCompleta]).TotalSeconds -lt 3) {
            return
        }

	        
        $global:procesadosRecientes[$rutaCompleta] = $ahora
	
			        
        if ((Split-Path $rutaCompleta -Parent) -eq (Resolve-Path $directorio).Path) {
            Start-Sleep -Milliseconds 1000
    
    
            
            # Asegura que aún exista antes de procesar
            if (Test-Path $rutaCompleta) {
                Procesar-Archivo $rutaCompleta
            }
        }
    }
    
    Register-ObjectEvent $watcher Changed -SourceIdentifier FileChanged -Action {
        
        $rutaCompleta = $Event.SourceEventArgs.FullPath
        $ahora = Get-Date
        
        # Verifica si el archivo aún existe en el directorio original
        if (-not (Test-Path $rutaCompleta)) {
            return
        }
        
        # Verifica si ya fue procesado recientemente
        if ($global:procesadosRecientes[$rutaCompleta] -and ($ahora - $global:procesadosRecientes[$rutaCompleta]).TotalSeconds -lt 3) {
            return
        }

	        
        $global:procesadosRecientes[$rutaCompleta] = $ahora
	
			        
        if ((Split-Path $rutaCompleta -Parent) -eq (Resolve-Path $directorio).Path) {
            Start-Sleep -Milliseconds 1000
    
    
            
            # Asegura que aún exista antes de procesar
            if (Test-Path $rutaCompleta) {
                
                Procesar-Archivo $rutaCompleta
            }
        }
    }
    


    while ($true) {
        Start-Sleep -Seconds 4
    }
}

# ===========================
#          MAIN
# ===========================

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
    Write-Output "El valor especificado en -cantidad NO es un número"
    exit 1
}

$cantidad = [int] $cantidad

if ($cantidad -lt 1) {
    Write-Output "El valor del parametro CANTIDAD no puede ser menor a 1"
    exit 1
}

if (-not (Test-Path $directorio -PathType Container)) {
    Write-Output "El directorio especificado en -directorio NO es válido"
    exit 1
}

if (-not (Test-Path $salida -PathType Container)) {
    Write-Output "El directorio especificado en -salida NO es válido"
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
        }
        else {
            Write-Output "PID muerto encontrado, limpiando..."
            Remove-Item $pidFile -Force
        }
    }
    Lanzar-Demonio
}

# Modo demonio
$script:contador = 0
Demonio