Import-Module ActiveDirectory

$csvFilePath = "C:\Users\Administrator\Downloads\final\Usuarios1.csv"

# Validar que existe el archivo CSV
if (-not (Test-Path $csvFilePath)) {
    Write-Error "No se encontró el archivo CSV en: $csvFilePath"
    exit
}

$data = Import-Csv -Path $csvFilePath -Encoding UTF8

Write-Host "`n========== INICIANDO PROCESO DE ELIMINACIÓN COMPLETA ==========" -ForegroundColor Cyan
Write-Host "ADVERTENCIA: Este proceso eliminará usuarios, OUs y recursos compartidos" -ForegroundColor Red
Write-Host "===============================================================`n" -ForegroundColor Cyan

$usuariosEliminados = 0
$usuariosNoEncontrados = 0
$errores = 0

# ==================== ELIMINACIÓN DE USUARIOS ====================
Write-Host "`nEliminando usuarios del CSV..." -ForegroundColor Yellow

foreach ($usuario in $data) {
    $codigo = $usuario.Codigo
    $apellido = $usuario.Apellido
    $nombre = $usuario.Nombre
    $carreraSigla = $usuario.Carrera
    
    # Limpiar datos
    $lastName = $apellido -replace " ", ""
    $firstName = $nombre -replace " ", ""
    
    # Generar patrón de búsqueda basado en la lógica de creación
    $nombre = $firstName -replace "[^a-zA-Z]", ""
    $apellido = $lastName -replace "[^a-zA-Z]", ""
    
    $nombrePart = if ($nombre.Length -ge 2) { $nombre.Substring(0, 2) } else { $nombre.PadRight(2, 'x') }
    $apellidoPart = if ($apellido.Length -ge 2) { $apellido.Substring(0, 2) } else { $apellido.PadRight(2, 'x') }
    
    if ([string]::IsNullOrWhiteSpace($nombre)) {
        $basePart = if ($apellido.Length -ge 4) { 
            $apellido.Substring(0, 4).ToLower() 
        }
        else { 
            $apellido.PadRight(4, 'x').ToLower() 
        }
    }
    else {
        $basePart = ($nombrePart + $apellidoPart).ToLower()
    }
    
    # Prefijo de carrera
    $prefijoCarrera = if ($carreraSigla.Length -ge 3) { 
        $carreraSigla.Substring(0, 3).ToLower() 
    }
    else { 
        $carreraSigla.ToLower().PadRight(3, 'x') 
    }
    
    # Buscar usuarios con el patrón: prefijoCarrera + basePart + *
    $patronBusqueda = "$prefijoCarrera$basePart*"
    
    try {
        $usuarios = Get-ADUser -Filter "SamAccountName -like '$patronBusqueda'" -ErrorAction SilentlyContinue
        
        if ($usuarios) {
            foreach ($adUser in $usuarios) {
                try {
                    Remove-ADUser -Identity $adUser.SamAccountName -Confirm:$false -ErrorAction Stop
                    Write-Host "Usuario eliminado: $($adUser.SamAccountName) ($firstName $lastName)" -ForegroundColor Green
                    $usuariosEliminados++
                }
                catch {
                    Write-Warning "Error al eliminar usuario $($adUser.SamAccountName): $_"
                    $errores++
                }
            }
        }
        else {
            Write-Host "Usuario no encontrado: $firstName $lastName (patrón: $patronBusqueda)" -ForegroundColor Yellow
            $usuariosNoEncontrados++
        }
    }
    catch {
        Write-Warning "Error al buscar usuario con patrón $patronBusqueda : $_"
        $errores++
    }
}

Write-Host "`n--- Resumen de eliminación de usuarios ---" -ForegroundColor Cyan
Write-Host "Usuarios eliminados: $usuariosEliminados" -ForegroundColor Green
Write-Host "Usuarios no encontrados: $usuariosNoEncontrados" -ForegroundColor Yellow
Write-Host "Errores: $errores" -ForegroundColor Red

# ==================== ELIMINACIÓN DE OUs ====================
Write-Host "`n`nEliminando estructura de OUs..." -ForegroundColor Yellow

$domainDn = "DC=suikacorp,DC=com"
$ousToDelete = @("UPB", "UPB_users")

foreach ($ouName in $ousToDelete) {
    $ouPath = "OU=$ouName,$domainDn"
    
    try {
        $ou = Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ouPath'" -ErrorAction SilentlyContinue
        
        if ($ou) {
            Write-Host "`nProcesando OU: $ouName" -ForegroundColor Cyan
            
            # Quitar protección contra eliminación en todos los objetos dentro de la OU
            Write-Host "  - Quitando protección de objetos internos..." -ForegroundColor Gray
            Get-ADObject -LDAPFilter "(objectClass=*)" -SearchBase $ouPath -SearchScope Subtree -ErrorAction SilentlyContinue |
                ForEach-Object {
                    try { 
                        Set-ADObject -Identity $_.DistinguishedName -ProtectedFromAccidentalDeletion $false -ErrorAction SilentlyContinue
                    } 
                    catch { }
                }
            
            # Quitar protección en la OU raíz
            Write-Host "  - Quitando protección de la OU raíz..." -ForegroundColor Gray
            try { 
                Set-ADOrganizationalUnit -Identity $ouPath -ProtectedFromAccidentalDeletion $false -ErrorAction Stop 
            } 
            catch { }
            
            # Eliminar grupos dentro de la OU primero
            Write-Host "  - Eliminando grupos..." -ForegroundColor Gray
            Get-ADGroup -Filter * -SearchBase $ouPath -SearchScope Subtree -ErrorAction SilentlyContinue |
                ForEach-Object {
                    try {
                        Remove-ADGroup -Identity $_.DistinguishedName -Confirm:$false -ErrorAction Stop
                    }
                    catch { }
                }
            
            # Eliminar recursivamente la OU y todo su contenido
            Write-Host "  - Eliminando OU y contenido..." -ForegroundColor Gray
            Remove-ADOrganizationalUnit -Identity $ouPath -Recursive -Confirm:$false -ErrorAction Stop
            
            Write-Host "OU '$ouName' eliminada correctamente" -ForegroundColor Green
        }
        else {
            Write-Host "La OU '$ouName' no existe" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Warning "Error al eliminar OU '$ouName': $_"
    }
}

# ==================== ELIMINACIÓN DE RECURSOS COMPARTIDOS ====================
Write-Host "`n`nEliminando recursos compartidos..." -ForegroundColor Yellow

$profileFolder = "C:\Profile_UPB"
$homeFolder = "C:\Home_UPB"
$profileShareName = "Profile_UPB$"
$homeShareName = "Home_UPB$"

# Eliminar recurso compartido Profile_UPB$
if (Get-SmbShare -Name $profileShareName -ErrorAction SilentlyContinue) {
    try {
        Remove-SmbShare -Name $profileShareName -Force -ErrorAction Stop
        Write-Host "Recurso compartido '$profileShareName' eliminado" -ForegroundColor Green
    }
    catch {
        Write-Warning "Error al eliminar compartido $profileShareName : $_"
    }
}
else {
    Write-Host "El recurso compartido '$profileShareName' no existe" -ForegroundColor Yellow
}

# Eliminar recurso compartido Home_UPB$
if (Get-SmbShare -Name $homeShareName -ErrorAction SilentlyContinue) {
    try {
        Remove-SmbShare -Name $homeShareName -Force -ErrorAction Stop
        Write-Host "Recurso compartido '$homeShareName' eliminado" -ForegroundColor Green
    }
    catch {
        Write-Warning "Error al eliminar compartido $homeShareName : $_"
    }
}
else {
    Write-Host "El recurso compartido '$homeShareName' no existe" -ForegroundColor Yellow
}

# Eliminar carpeta Profile_UPB
if (Test-Path $profileFolder) {
    try {
        # Tomar propiedad de la carpeta y todos sus contenidos
        takeown /f $profileFolder /r /d y | Out-Null
        icacls $profileFolder /grant "Administrators:(F)" /t /c /q | Out-Null
        
        Remove-Item -Path $profileFolder -Recurse -Force -ErrorAction Stop
        Write-Host "Carpeta $profileFolder eliminada" -ForegroundColor Green
    }
    catch {
        Write-Warning "Error al eliminar carpeta $profileFolder : $_"
    }
}
else {
    Write-Host "La carpeta $profileFolder no existe" -ForegroundColor Yellow
}

# Eliminar carpeta Home_UPB
if (Test-Path $homeFolder) {
    try {
        # Tomar propiedad de la carpeta y todos sus contenidos
        takeown /f $homeFolder /r /d y | Out-Null
        icacls $homeFolder /grant "Administrators:(F)" /t /c /q | Out-Null
        
        Remove-Item -Path $homeFolder -Recurse -Force -ErrorAction Stop
        Write-Host "Carpeta $homeFolder eliminada" -ForegroundColor Green
    }
    catch {
        Write-Warning "Error al eliminar carpeta $homeFolder : $_"
    }
}
else {
    Write-Host "La carpeta $homeFolder no existe" -ForegroundColor Yellow
}

Write-Host "`n========== PROCESO DE ELIMINACIÓN COMPLETADO ==========`n" -ForegroundColor Cyan