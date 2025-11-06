# Script Maestro - Ejecución Secuencial Automática de Scripts
# Ejecuta los scripts de configuración en orden: 01.ps1, 03.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SCRIPT MAESTRO - GESTIÓN DE USUARIOS" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$scripts = @("CreacionOU's&RecursosCompartidos.ps1", "CreacionUsuarios.ps1")

# Verificar que todos los scripts existen antes de ejecutar
Write-Host "Verificando scripts..." -ForegroundColor Yellow
$allExist = $true
foreach($script in $scripts){
    $fullPath = Join-Path $scriptPath $script
    if(-not (Test-Path $fullPath)){
        Write-Host "ERROR: No se encuentra el script $script en $scriptPath" -ForegroundColor Red
        $allExist = $false
    }
    else{
        Write-Host "✓ $script encontrado" -ForegroundColor Green
    }
}

if(-not $allExist){
    Write-Host "`nNo se pueden ejecutar los scripts. Verifique que todos existan." -ForegroundColor Red
    exit 1
}

Write-Host "`nTodos los scripts encontrados. Iniciando ejecución automática...`n" -ForegroundColor Green
Start-Sleep -Seconds 2

# Ejecutar cada script en orden automáticamente
$scriptNumber = 1
$exitCode = 0

foreach($script in $scripts){
    $fullPath = Join-Path $scriptPath $script
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  EJECUTANDO SCRIPT $scriptNumber de $($scripts.Count): $script" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    try {
        # Ejecutar el script
        & $fullPath
        
        if($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null){
            Write-Host "`n⚠ ADVERTENCIA: El script $script finalizó con código de salida $LASTEXITCODE" -ForegroundColor Yellow
            $exitCode = $LASTEXITCODE
        }
        else{
            Write-Host "`n✓ Script $script completado exitosamente" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "`n✗ ERROR al ejecutar $script : $_" -ForegroundColor Red
        $exitCode = 1
    }
    
    $scriptNumber++
    
    # Pequeña pausa entre scripts
    if($scriptNumber -le $scripts.Count){
        Start-Sleep -Seconds 2
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  EJECUCIÓN COMPLETADA" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "`nTodos los scripts han sido ejecutados." -ForegroundColor Green
Write-Host "Revise los mensajes anteriores para verificar el estado de cada script.`n" -ForegroundColor White

exit $exitCode