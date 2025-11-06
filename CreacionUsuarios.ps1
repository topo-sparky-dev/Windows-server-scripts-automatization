Import-Module ActiveDirectory

$csvFilePath = "C:\Users\Administrator\Downloads\final\Usuarios1.csv"
$carrerasCsvPath = "C:\Users\Administrator\Downloads\final\Carreras1.csv"

# Validar que los archivos CSV existan
if (-not (Test-Path $csvFilePath)) {
    Write-Error "No se encuentra el archivo: $csvFilePath"
    exit
}

if (-not (Test-Path $carrerasCsvPath)) {
    Write-Error "No se encuentra el archivo: $carrerasCsvPath"
    exit
}

$data = Import-Csv -Path $csvFilePath -Encoding UTF8
$carrerasData = Import-Csv -Path $carrerasCsvPath -Encoding UTF8

# Crear hashtable dinámico desde el CSV de carreras (Sigla -> Carrera completa)
$carrerasMap = @{}
foreach ($carrera in $carrerasData) {
    $carrerasMap[$carrera.Sigla] = $carrera.Carrera
}

# Función para obtener nombre completo de carrera
function Get-NombreCarrera {
    param(
        [string]$Sigla
    )
    
    if ($carrerasMap.ContainsKey($Sigla)) {
        return $carrerasMap[$Sigla]
    }
    return $Sigla
}

# Función para generar username único con prefijo de carrera y milisegundos
function Get-UniqueUsername {
    param(
        [string]$Nombre,
        [string]$Apellido,
        [string]$CarreraSigla
    )
    
    # Limpiar espacios y caracteres especiales
    $nombre = $Nombre -replace " ", "" -replace "[^a-zA-Z]", ""
    $apellido = $Apellido -replace " ", "" -replace "[^a-zA-Z]", ""
    
    # Tomar primeras 2 letras del nombre y 2 del apellido
    $nombrePart = if ($nombre.Length -ge 2) { $nombre.Substring(0, 2) } else { $nombre.PadRight(2, 'x') }
    $apellidoPart = if ($apellido.Length -ge 2) { $apellido.Substring(0, 2) } else { $apellido.PadRight(2, 'x') }
    
    # Si no hay nombre, usar 4 letras del apellido
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
    
    # Prefijo de carrera (primeras 3 letras de la sigla)
    $prefijoCarrera = if ($CarreraSigla.Length -ge 3) { 
        $CarreraSigla.Substring(0, 3).ToLower() 
    }
    else { 
        $CarreraSigla.ToLower().PadRight(3, 'x') 
    }
    
    # Obtener milisegundos actuales (últimos 4 dígitos)
    $timestamp = [DateTime]::Now
    $milliseconds = $timestamp.ToString("ffff")
    
    # Construir username: prefijoCarrera(3) + basePart(4) + milliseconds(4) = 11 caracteres
    $username = $prefijoCarrera + $basePart + $milliseconds
    
    # Verificar unicidad, si existe, regenerar con nuevos milisegundos
    $counter = 0
    while ((Get-ADUser -Filter "SamAccountName -eq '$username'" -ErrorAction SilentlyContinue) -and $counter -lt 100) {
        Start-Sleep -Milliseconds 10
        $timestamp = [DateTime]::Now
        $milliseconds = $timestamp.ToString("ffff")
        $username = $prefijoCarrera + $basePart + $milliseconds
        $counter++
    }
    
    if ($counter -ge 100) {
        Write-Error "No se pudo generar username único para $Nombre $Apellido después de 100 intentos"
        return $null
    }
    
    return $username
}

# Función para verificar si un email ya existe en AD
function Test-EmailExists {
    param(
        [string]$Email
    )
    
    $existingUser = Get-ADUser -Filter "EmailAddress -eq '$Email'" -ErrorAction SilentlyContinue
    return ($null -ne $existingUser)
}

# Procesar cada usuario del CSV
foreach ($usuario in $data) {
    
    $codigo = $usuario.Codigo
    $apellido = $usuario.Apellido
    $nombre = $usuario.Nombre
    $carreraSigla = $usuario.Carrera
    $facultad = $usuario.Facultad
    $campus = $usuario.Campus
    $rol = $usuario.Rol
    $celular = $usuario.Celular
    $fechaNacimiento = $usuario.FechaNacimiento
    $anioIngreso = $usuario.AnioIngreso
    
    # Limpiar datos
    $lastName = $apellido -replace " ", ""
    $firstName = $nombre -replace " ", ""
    
    # Generar username único con prefijo de carrera y milisegundos
    $username = Get-UniqueUsername -Nombre $firstName -Apellido $lastName -CarreraSigla $carreraSigla
    
    if ($null -eq $username) {
        Write-Output "Error: No se pudo crear username para $firstName $lastName"
        continue
    }
    
    # Generar email único basado en el username
    $email = "$username@suikacorp.com"
    
    # Verificar si el email ya existe
    if (Test-EmailExists -Email $email) {
        Write-Output "Error: El email $email ya existe en AD"
        continue
    }
    
    # Crear display name
    $displayName = if ([string]::IsNullOrWhiteSpace($firstName)) { 
        "$lastName" 
    }
    else { 
        "$firstName $lastName" 
    }
    
    # Obtener nombre completo de la carrera desde el CSV
    $nombreCarreraCompleto = Get-NombreCarrera -Sigla $carreraSigla
    
    # Crear descripción con código y nombre completo de carrera
    $descripcion = "Codigo: $codigo. Carrera: $nombreCarreraCompleto. Facultad: $facultad. Campus: $campus."
    
    $pass = ConvertTo-SecureString "Pass123" -AsPlainText -Force
    
    # Determinar la OU según el rol
    $ouPath = if ($rol -eq "Estudiante") {
        "OU=Estudiantes,OU=UPB_users,DC=suikacorp,DC=com"
    }
    elseif ($rol -eq "Profesor") {
        "OU=Docentes,OU=UPB_users,DC=suikacorp,DC=com"
    }
    else {
        "CN=Users,DC=suikacorp,DC=com"
    }
    
    # Verificar si el usuario ya existe
    if (-not (Get-ADUser -Filter "SamAccountName -eq '$username'" -ErrorAction SilentlyContinue)) {
        
        try {
            $newUserParams = @{
                Name                     = $displayName
                GivenName                = if ([string]::IsNullOrWhiteSpace($firstName)) { $lastName } else { $firstName }
                Surname                  = $lastName
                Department               = $facultad
                Office                   = $campus
                EmailAddress             = $email
                MobilePhone              = $celular
                Description              = $descripcion
                SamAccountName           = $username
                UserPrincipalName        = "$username@suikacorp.com"
                AccountPassword          = $pass
                Path                     = $ouPath
                HomeDirectory            = "\\amadeus\Home_UPB$\$username"
                HomeDrive                = "S:"
                ProfilePath              = "\\amadeus\Profile_UPB$\$username"
                Enabled                  = $true
                ChangePasswordAtLogon    = $true
            }
            
            New-ADUser @newUserParams
            
            # Agregar a grupos según el rol
            if ($rol -eq "Estudiante") {
                $groupName = "Estudiantes-$carreraSigla-$campus"
                if (Get-ADGroup -Filter "Name -eq '$groupName'" -ErrorAction SilentlyContinue) {
                    Add-ADGroupMember -Identity $groupName -Members $username -ErrorAction Stop
                    Write-Output "Usuario $username agregado al grupo: $groupName"
                }
                else {
                    Write-Warning "El grupo $groupName no existe"
                }
            }
            elseif ($rol -eq "Profesor") {
                $groupName = "Docentes-$carreraSigla-$campus"
                if (Get-ADGroup -Filter "Name -eq '$groupName'" -ErrorAction SilentlyContinue) {
                    Add-ADGroupMember -Identity $groupName -Members $username -ErrorAction Stop
                    Write-Output "Usuario $username agregado al grupo: $groupName"
                }
                else {
                    Write-Warning "El grupo $groupName no existe"
                }
            }
            
            Write-Output "Usuario creado: $username | Email: $email | Codigo: $codigo | Carrera: $nombreCarreraCompleto"
        }
        catch {
            Write-Error "Error al crear usuario $username : $_"
        }
    }
    else {
        Write-Output "El usuario $username ya existe"
    }
}

Write-Output "`nProceso completado."