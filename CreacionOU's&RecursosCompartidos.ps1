Import-Module ActiveDirectory

# Ruta del archivo CSV
$csvPath = "C:\Users\Administrator\Downloads\final\Carreras1.csv"

# Validar que existe el archivo CSV
if (-not (Test-Path $csvPath)) {
    Write-Error "No se encontró el archivo CSV en: $csvPath"
    exit
}

# Leer el CSV
$carreras = Import-Csv -Path $csvPath -Encoding UTF8

Write-Output "=== INICIANDO CREACIÓN DE ESTRUCTURA DE OUs Y GRUPOS ==="

# ==================== CREACIÓN DE ESTRUCTURA DE OUs ====================

# Crear OU principal UPB
$ouUPB = "OU=UPB,DC=suikacorp,DC=com"
if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ouUPB'" -ErrorAction SilentlyContinue)) {
    New-ADOrganizationalUnit -Name "UPB" -Path "DC=suikacorp,DC=com"
    Write-Output "[CREADO] OU UPB"
} else {
    Write-Output "[EXISTE] OU UPB"
}

# Crear OU principal UPB_users
$ouUPBUsers = "OU=UPB_users,DC=suikacorp,DC=com"
if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ouUPBUsers'" -ErrorAction SilentlyContinue)) {
    New-ADOrganizationalUnit -Name "UPB_users" -Path "DC=suikacorp,DC=com"
    Write-Output "[CREADO] OU UPB_users"
} else {
    Write-Output "[EXISTE] OU UPB_users"
}

# Crear OUs dentro de UPB_users (Estudiantes y Docentes)
$userTypes = @("Estudiantes", "Docentes")
foreach ($userType in $userTypes) {
    $userTypeOU = "OU=$userType,OU=UPB_users,DC=suikacorp,DC=com"
    
    if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$userTypeOU'" -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $userType -Path "OU=UPB_users,DC=suikacorp,DC=com"
        Write-Output "[CREADO] OU $userType en UPB_users"
    } else {
        Write-Output "[EXISTE] OU $userType en UPB_users"
    }
}

# Obtener campus únicos del CSV
$campuses = $carreras | Select-Object -ExpandProperty Campus -Unique | Where-Object { $_ -ne $null -and $_ -ne "" }

# Crear OUs de Campus dentro de UPB
foreach ($campus in $campuses) {
    $campusOU = "OU=$campus,OU=UPB,DC=suikacorp,DC=com"
    
    if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$campusOU'" -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $campus -Path "OU=UPB,DC=suikacorp,DC=com"
        Write-Output "[CREADO] Campus: $campus"
    } else {
        Write-Output "[EXISTE] Campus: $campus"
    }
    
    # Obtener facultades únicas para este campus
    $facultadesCampus = $carreras | Where-Object { $_.Campus -eq $campus } | 
                        Select-Object -ExpandProperty Facultad -Unique | 
                        Where-Object { $_ -ne $null -and $_ -ne "" }
    
    # Crear OUs de Facultades dentro del campus
    foreach ($facultad in $facultadesCampus) {
        $facultadOU = "OU=$facultad,OU=$campus,OU=UPB,DC=suikacorp,DC=com"
        
        if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$facultadOU'" -ErrorAction SilentlyContinue)) {
            New-ADOrganizationalUnit -Name $facultad -Path "OU=$campus,OU=UPB,DC=suikacorp,DC=com"
            Write-Output "[CREADO] Facultad: $facultad en $campus"
        } else {
            Write-Output "[EXISTE] Facultad: $facultad en $campus"
        }
        
        # Obtener carreras para esta facultad y campus
        $carrerasFacultad = $carreras | Where-Object { 
            $_.Campus -eq $campus -and $_.Facultad -eq $facultad -and 
            $_.Sigla -ne $null -and $_.Sigla -ne "" 
        }
        
        # Crear OUs de Carreras y sus grupos
        foreach ($carrera in $carrerasFacultad) {
            $sigla = $carrera.Sigla
            $carreraOU = "OU=$sigla,OU=$facultad,OU=$campus,OU=UPB,DC=suikacorp,DC=com"
            
            if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$carreraOU'" -ErrorAction SilentlyContinue)) {
                New-ADOrganizationalUnit -Name $sigla -Path "OU=$facultad,OU=$campus,OU=UPB,DC=suikacorp,DC=com"
                Write-Output "[CREADO] Carrera: $sigla en $facultad - $campus"
            } else {
                Write-Output "[EXISTE] Carrera: $sigla en $facultad - $campus"
            }
            
            # Crear grupos de Estudiantes y Docentes dentro de cada carrera
            $grupos = @("Estudiantes", "Docentes")
            
            foreach ($grupo in $grupos) {
                $groupName = "$grupo-$sigla-$campus"
                $groupPath = "OU=$sigla,OU=$facultad,OU=$campus,OU=UPB,DC=suikacorp,DC=com"
                
                if (-not (Get-ADGroup -Filter "Name -eq '$groupName'" -ErrorAction SilentlyContinue)) {
                    try {
                        New-ADGroup -Name $groupName -Path $groupPath -GroupScope Global -GroupCategory Security
                        Write-Output "[CREADO] Grupo: $groupName"
                    } catch {
                        Write-Warning "[ERROR] No se pudo crear el grupo $groupName : $_"
                    }
                } else {
                    Write-Output "[EXISTE] Grupo: $groupName"
                }
            }
        }
    }
}

Write-Output "`n=== ESTRUCTURA DE OUs Y GRUPOS COMPLETADA ==="

# ==================== CREACIÓN DE RECURSOS COMPARTIDOS ====================

Write-Output "`n=== INICIANDO CREACIÓN DE RECURSOS COMPARTIDOS ==="

# Configuración de carpetas compartidas
$profileFolder = "C:\Profile_UPB"
$homeFolder = "C:\Home_UPB"
$profileShareName = "Profile_UPB$"
$homeShareName = "Home_UPB$"

# Función para configurar permisos NTFS para Profile (perfiles móviles)
function Set-ProfileFolderPermissions {
    param(
        [string]$FolderPath
    )
    
    try {
        $acl = Get-Acl $FolderPath
        
        # Deshabilitar herencia
        $acl.SetAccessRuleProtection($true, $false)
        
        # Eliminar todos los permisos existentes
        $acl.Access | ForEach-Object { $acl.RemoveAccessRule($_) | Out-Null }
        
        # SYSTEM - Full Control
        $systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "SYSTEM",
            [System.Security.AccessControl.FileSystemRights]::FullControl,
            [System.Security.AccessControl.InheritanceFlags]"ContainerInherit,ObjectInherit",
            [System.Security.AccessControl.PropagationFlags]::None,
            [System.Security.AccessControl.AccessControlType]::Allow
        )
        $acl.AddAccessRule($systemRule)
        
        # Administrators - Full Control
        $adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "Administrators",
            [System.Security.AccessControl.FileSystemRights]::FullControl,
            [System.Security.AccessControl.InheritanceFlags]"ContainerInherit,ObjectInherit",
            [System.Security.AccessControl.PropagationFlags]::None,
            [System.Security.AccessControl.AccessControlType]::Allow
        )
        $acl.AddAccessRule($adminRule)
        
        # CREATOR OWNER - Full Control (solo en subcarpetas)
        $creatorRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "CREATOR OWNER",
            [System.Security.AccessControl.FileSystemRights]::FullControl,
            [System.Security.AccessControl.InheritanceFlags]"ContainerInherit,ObjectInherit",
            [System.Security.AccessControl.PropagationFlags]::InheritOnly,
            [System.Security.AccessControl.AccessControlType]::Allow
        )
        $acl.AddAccessRule($creatorRule)
        
        # Users - Crear carpetas y atravesar (CRÍTICO PARA PERFILES)
        $usersRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "Users",
            [System.Security.AccessControl.FileSystemRights]"CreateDirectories, AppendData, ReadPermissions, Traverse, Synchronize",
            [System.Security.AccessControl.InheritanceFlags]::None,
            [System.Security.AccessControl.PropagationFlags]::None,
            [System.Security.AccessControl.AccessControlType]::Allow
        )
        $acl.AddAccessRule($usersRule)
        
        # Everyone - Listar carpeta (permite ver su propia carpeta)
        $everyoneRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "Everyone",
            [System.Security.AccessControl.FileSystemRights]"ReadAndExecute, ListDirectory",
            [System.Security.AccessControl.InheritanceFlags]::None,
            [System.Security.AccessControl.PropagationFlags]::None,
            [System.Security.AccessControl.AccessControlType]::Allow
        )
        $acl.AddAccessRule($everyoneRule)
        
        Set-Acl -Path $FolderPath -AclObject $acl
        Write-Output "[CONFIGURADO] Permisos NTFS para Profile en $FolderPath"
        
    } catch {
        Write-Warning "[ERROR] No se pudieron configurar permisos NTFS en $FolderPath : $_"
    }
}

# Función para configurar permisos NTFS para Home (carpetas personales)
function Set-HomeFolderPermissions {
    param(
        [string]$FolderPath
    )
    
    try {
        $acl = Get-Acl $FolderPath
        
        # Deshabilitar herencia
        $acl.SetAccessRuleProtection($true, $false)
        
        # Eliminar todos los permisos existentes
        $acl.Access | ForEach-Object { $acl.RemoveAccessRule($_) | Out-Null }
        
        # SYSTEM - Full Control
        $systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "SYSTEM",
            [System.Security.AccessControl.FileSystemRights]::FullControl,
            [System.Security.AccessControl.InheritanceFlags]"ContainerInherit,ObjectInherit",
            [System.Security.AccessControl.PropagationFlags]::None,
            [System.Security.AccessControl.AccessControlType]::Allow
        )
        $acl.AddAccessRule($systemRule)
        
        # Administrators - Full Control
        $adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "Administrators",
            [System.Security.AccessControl.FileSystemRights]::FullControl,
            [System.Security.AccessControl.InheritanceFlags]"ContainerInherit,ObjectInherit",
            [System.Security.AccessControl.PropagationFlags]::None,
            [System.Security.AccessControl.AccessControlType]::Allow
        )
        $acl.AddAccessRule($adminRule)
        
        # CREATOR OWNER - Full Control (solo en subcarpetas)
        $creatorRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "CREATOR OWNER",
            [System.Security.AccessControl.FileSystemRights]::FullControl,
            [System.Security.AccessControl.InheritanceFlags]"ContainerInherit,ObjectInherit",
            [System.Security.AccessControl.PropagationFlags]::InheritOnly,
            [System.Security.AccessControl.AccessControlType]::Allow
        )
        $acl.AddAccessRule($creatorRule)
        
        # Users - Crear carpetas y atravesar
        $usersRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "Users",
            [System.Security.AccessControl.FileSystemRights]"CreateDirectories, AppendData, ReadPermissions, Traverse, Synchronize",
            [System.Security.AccessControl.InheritanceFlags]::None,
            [System.Security.AccessControl.PropagationFlags]::None,
            [System.Security.AccessControl.AccessControlType]::Allow
        )
        $acl.AddAccessRule($usersRule)
        
        Set-Acl -Path $FolderPath -AclObject $acl
        Write-Output "[CONFIGURADO] Permisos NTFS para Home en $FolderPath"
        
    } catch {
        Write-Warning "[ERROR] No se pudieron configurar permisos NTFS en $FolderPath : $_"
    }
}

# Crear carpeta Profile_UPB
if (-not (Test-Path $profileFolder)) {
    New-Item -Path $profileFolder -ItemType Directory -Force | Out-Null
    Write-Output "[CREADO] Carpeta: $profileFolder"
} else {
    Write-Output "[EXISTE] Carpeta: $profileFolder"
}

# Crear carpeta Home_UPB
if (-not (Test-Path $homeFolder)) {
    New-Item -Path $homeFolder -ItemType Directory -Force | Out-Null
    Write-Output "[CREADO] Carpeta: $homeFolder"
} else {
    Write-Output "[EXISTE] Carpeta: $homeFolder"
}

# Configurar permisos NTFS específicos
Set-ProfileFolderPermissions -FolderPath $profileFolder
Set-HomeFolderPermissions -FolderPath $homeFolder

# Crear recurso compartido Profile_UPB$
if (-not (Get-SmbShare -Name $profileShareName -ErrorAction SilentlyContinue)) {
    try {
        New-SmbShare -Name $profileShareName `
                     -Path $profileFolder `
                     -FullAccess "Everyone" `
                     -CachingMode Manual `
                     -FolderEnumerationMode AccessBased `
                     -Description "Perfiles móviles de usuarios UPB" | Out-Null
        Write-Output "[CREADO] Recurso compartido: $profileShareName"
        Write-Output "           - Path: $profileFolder"
        Write-Output "           - Permisos SMB: Everyone (Full)"
        Write-Output "           - Caching: Manual (recomendado para perfiles)"
        Write-Output "           - ABE: Habilitado"
    } catch {
        Write-Warning "[ERROR] No se pudo crear el recurso compartido $profileShareName : $_"
    }
} else {
    Write-Output "[EXISTE] Recurso compartido: $profileShareName"
}

# Crear recurso compartido Home_UPB$
if (-not (Get-SmbShare -Name $homeShareName -ErrorAction SilentlyContinue)) {
    try {
        New-SmbShare -Name $homeShareName `
                     -Path $homeFolder `
                     -FullAccess "Everyone" `
                     -CachingMode Documents `
                     -FolderEnumerationMode AccessBased `
                     -Description "Carpetas personales de usuarios UPB" | Out-Null
        Write-Output "[CREADO] Recurso compartido: $homeShareName"
        Write-Output "           - Path: $homeFolder"
        Write-Output "           - Permisos SMB: Everyone (Full)"
        Write-Output "           - Caching: Documents"
        Write-Output "           - ABE: Habilitado"
    } catch {
        Write-Warning "[ERROR] No se pudo crear el recurso compartido $homeShareName : $_"
    }
} else {
    Write-Output "[EXISTE] Recurso compartido: $homeShareName"
}

Write-Output "`n=== RECURSOS COMPARTIDOS COMPLETADOS ==="
Write-Output ""
Write-Output "Recursos compartidos creados:"
Write-Output "  \\$env:COMPUTERNAME\$profileShareName"
Write-Output "  \\$env:COMPUTERNAME\$homeShareName"
Write-Output ""
Write-Output "Configuración aplicada:"
Write-Output "  PROFILE_UPB:"
Write-Output "    - Permisos NTFS: SYSTEM, Administrators, CREATOR OWNER, Users, Everyone"
Write-Output "    - Permisos SMB: Everyone (Full)"
Write-Output "    - Caching: Manual (óptimo para perfiles móviles)"
Write-Output "    - ABE: Habilitado"
Write-Output ""
Write-Output "  HOME_UPB:"
Write-Output "    - Permisos NTFS: SYSTEM, Administrators, CREATOR OWNER, Users"
Write-Output "    - Permisos SMB: Everyone (Full)"
Write-Output "    - Caching: Documents"
Write-Output "    - ABE: Habilitado"
Write-Output ""

Write-Output "=== SCRIPT COMPLETADO EXITOSAMENTE ==="