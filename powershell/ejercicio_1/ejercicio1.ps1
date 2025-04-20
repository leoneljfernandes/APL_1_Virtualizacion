Param (
    [Parameter(Mandatory=$true)]
    [string]$Directorio,
    [string]$Archivo,
    [switch]$Pantalla,
    [switch]$Help
)

function Get-Ayuda {
    Write-Host "Bienvenido al script de procesamiento de datos meteorologicos."
    Write-Host "Puede optar por las siguientes opciones:"
    Write-Host "  -Directorio <directorio>   Especifica el directorio de trabajo."
    Write-Host "  -Archivo <archivo>         Especifica el archivo de salida."   
    Write-Host "  -Pantalla                  Especifica la salida a pantalla."
    Write-Host "  -Help                      Muestra esta ayuda."
    Write-Host "Ejemplo de uso: .\script.ps1 -Directorio 'C:\ruta\al\directorio' -Archivo 'archivo.txt' -Pantalla"
    Write-Host "Ejemplo de uso: .\script.ps1 -Help"
    Write-Host "Si elige obtener el resultado mediante un archivo de salida no sera posible visualizarlo en pantalla."
}

if ($Help) {
    Get-Ayuda
    exit
}

# Validaciones
if (-not $Archivo -and -not $Pantalla) {
    Write-Host "Error: Debe especificar al menos un argumento de salida."
    Get-Ayuda
    exit
}

if ($Pantalla -and $Archivo) {
    Write-Host "Error: No puede especificar tanto -Pantalla como -Archivo."
    Get-Ayuda
    exit
}

if (-not (Test-Path $Directorio)) {
    Write-Host "Error: El directorio especificado no existe."
    exit
}

$archivos = Get-ChildItem -Path $Directorio -Filter "*.csv"

if($archivos.Count -eq 0) {
    Write-Host "Error: No se encontraron archivos CSV en el directorio especificado."
    exit
}

# Objeto para almacenar todos los resultados
$resultadosGlobales = @{}

foreach ($arch in $archivos) {
    Write-Host "`nProcesando archivo: $($arch.FullName)" -ForegroundColor Cyan

    try {
        # Importar CSV con validación de estructura
        $datos = Import-Csv -Path $arch.FullName -Header "Id", "Fecha", "Hora", "Ubicacion", "Temperatura" -ErrorAction Stop
        
        # Verificar si se importaron datos correctamente
        if ($datos.Count -eq 0) {
            Write-Host "Advertencia: El archivo $($arch.Name) no contiene datos" -ForegroundColor Yellow
            continue
        }
        
        # Procesamos los datos
        foreach ($registro in $datos){
            try{
                $temp = [double]$registro.Temperatura
                $fecha = $registro.Fecha
                $ubicacion = $registro.Ubicacion

                if (-not $resultadosGlobales.ContainsKey($fecha)) {
                        $resultadosGlobales[$fecha] = @{}
                }

                if (-not $resultadosGlobales[$fecha].ContainsKey($ubicacion)) {
                    $resultadosGlobales[$fecha][$ubicacion] = @{
                        Suma = 0
                        Cuenta = 0
                        Min = $temp
                        Max = $temp
                    }
                }

                $stats = $resultadosGlobales[$fecha][$ubicacion]
                if ($temp -lt $stats.Min) { 
                    $stats.Min = $temp 
                }
                if ($temp -gt $stats.Max) { 
                    $stats.Max = $temp
                }
                $stats.Suma += $temp
                $stats.Cuenta++

            } catch {
                Write-Host "Error procesando registro: $_" -ForegroundColor Yellow
            }
        }
    } catch {
                Write-Host "Error procesando registro $($registro.Id): $_" -ForegroundColor Yellow
    }
}

# Generar salida
$salidaFinal = @{
    fechas = @{}
}

foreach ($fecha in $resultadosGlobales.Keys | Sort-Object) {
    $salidaFinal.fechas[$fecha] = @{}

    foreach ($ubicacion in $resultadosGlobales[$fecha].Keys | Sort-Object) {
        $stats = $resultadosGlobales[$fecha][$ubicacion]
        $promedio = $stats.Suma / $stats.Cuenta

        $salidaFinal.fechas[$fecha][$ubicacion] = @{
            Min = [math]::Round($stats.Min, 2)
            Max = [math]::Round($stats.Max, 2)
            Promedio = [math]::Round($promedio, 2)
        }
    }
}

# Convertir a JSON
$jsonResultado = $salidaFinal | ConvertTo-Json -Depth 10

# Manejar salida
if ($Archivo) {
    #genero la ruta de salida con el nombre de Archivo en json
    $rutaSalida = Join-Path -Path $Directorio -ChildPath $Archivo.json
    try {
        $jsonResultado | Out-File -FilePath $rutaSalida -Encoding UTF8
        Write-Host "`nResultados guardados en: $rutaSalida" -ForegroundColor Green
    }
    catch {
        Write-Host "Error al guardar archivo: $_" -ForegroundColor Red
    }
}

if ($Pantalla) {
    Write-Host "`nResultados:`n" -ForegroundColor Green
    Write-Host $jsonResultado
}