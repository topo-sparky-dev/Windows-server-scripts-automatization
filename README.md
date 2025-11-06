# Active Directory User Management Scripts for UPB

This repository contains a set of PowerShell scripts designed to automate the management of users, organizational units (OUs), groups, and shared resources in an Active Directory environment for the Universidad Privada Boliviana (UPB). The scripts are tailored for creating student and professor accounts based on CSV data, setting up directory structures, and configuring roaming profiles and home directories.

These scripts are intended for system administrators managing an educational domain (e.g., `suikacorp.com`). They handle bulk operations efficiently but should be used with caution as they modify Active Directory objects and file shares.

## Features

- **OU and Group Creation**: Automatically builds a hierarchical OU structure based on campuses, faculties, and careers from a CSV file. Creates security groups for students and professors per career and campus.
- **User Creation**: Generates unique usernames and emails for users (students and professors) from a user CSV. Assigns them to appropriate OUs and groups, sets up home directories and roaming profiles.
- **Shared Resources**: Configures shared folders for home directories and profiles with appropriate NTFS and SMB permissions.
- **Reset Script**: A cleanup script to delete all created users, OUs, groups, and shared resources, restoring the environment to a default state.
- **Master Script**: Orchestrates the execution of the creation scripts in sequence.

## Prerequisites

- **Operating System**: Windows Server with Active Directory Domain Services (AD DS) installed.
- **PowerShell Version**: PowerShell 5.1 or later.
- **Modules**: `ActiveDirectory` module (imported automatically in scripts).
- **Permissions**: Run as a Domain Administrator.
- **CSV Files**:
  - `Usuarios1.csv`: Contains user data (columns: Codigo, Apellido, Nombre, Carrera, Facultad, Campus, Rol, Celular, FechaNacimiento, AnioIngreso).
  - `Carreras1.csv`: Contains career data (columns: Sigla, Carrera, Facultad, Campus).
- **File Paths**: Scripts assume CSVs are located at `C:\Users\Administrator\Downloads\final\`. Update paths in scripts if needed.
- **Server Configuration**: The domain should be `suikacorp.com`. Shared folders are created on the local C: drive (e.g., `C:\Profile_UPB` and `C:\Home_UPB`).

**Note**: Ensure the server has sufficient disk space for shared folders. Back up your Active Directory before running these scripts.

## Installation

1. Clone the repository:
git clone https://github.com/yourusername/your-repo-name.git
2. Place the required CSV files (`Usuarios1.csv` and `Carreras1.csv`) in the specified path or update the script variables accordingly.
3. Open PowerShell as Administrator.
4. Navigate to the repository directory.
5. Ensure the `ActiveDirectory` module is available (it comes with RSAT tools).

## Usage

### 1. Master Script: All.ps1
This is the entry point for creating the entire structure and users automatically.

- **Purpose**: Verifies script existence, then runs `CreacionOU's&RecursosCompartidos.ps1` followed by `CreacionUsuarios.ps1`.
- **Execution**:
.\All.ps1
- **Output**: Console logs showing progress, successes, and any errors.

### 2. OU and Shared Resources Creation: CreacionOU's&RecursosCompartidos.ps1
- **Purpose**: Creates OUs for campuses, faculties, and careers; creates groups; sets up shared folders for profiles and home directories with permissions.
- **Execution**:
.\CreacionOU's&RecursosCompartidos.ps1
- **Dependencies**: Requires `Carreras1.csv`.
- **Notes**: Shared paths are `\\amadeus\Profile_UPB$` and `\\amadeus\Home_UPB$` (assuming the server name is `amadeus` – update if different).

### 3. User Creation: CreacionUsuarios.ps1
- **Purpose**: Creates AD users from `Usuarios1.csv`, generates unique usernames (e.g., career prefix + name parts + timestamp), assigns to OUs/groups, sets emails, descriptions, home directories, and profiles.
- **Execution**:
Necesito que me hagas el readme para mi github de esto en ingles, damelo completoAll.ps1CreacionUsuarios.ps1CreacionOU's&RecursosCompartidos.ps1RestaurarPordefecto.ps1Active Directory User Management Scripts for UPB
This repository contains a set of PowerShell scripts designed to automate the management of users, organizational units (OUs), groups, and shared resources in an Active Directory environment for the Universidad Privada Boliviana (UPB). The scripts are tailored for creating student and professor accounts based on CSV data, setting up directory structures, and configuring roaming profiles and home directories.
These scripts are intended for system administrators managing an educational domain (e.g., suikacorp.com). They handle bulk operations efficiently but should be used with caution as they modify Active Directory objects and file shares.
Features

OU and Group Creation: Automatically builds a hierarchical OU structure based on campuses, faculties, and careers from a CSV file. Creates security groups for students and professors per career and campus.
User Creation: Generates unique usernames and emails for users (students and professors) from a user CSV. Assigns them to appropriate OUs and groups, sets up home directories and roaming profiles.
Shared Resources: Configures shared folders for home directories and profiles with appropriate NTFS and SMB permissions.
Reset Script: A cleanup script to delete all created users, OUs, groups, and shared resources, restoring the environment to a default state.
Master Script: Orchestrates the execution of the creation scripts in sequence.

Prerequisites

Operating System: Windows Server with Active Directory Domain Services (AD DS) installed.
PowerShell Version: PowerShell 5.1 or later.
Modules: ActiveDirectory module (imported automatically in scripts).
Permissions: Run as a Domain Administrator.
CSV Files:

Usuarios1.csv: Contains user data (columns: Codigo, Apellido, Nombre, Carrera, Facultad, Campus, Rol, Celular, FechaNacimiento, AnioIngreso).
Carreras1.csv: Contains career data (columns: Sigla, Carrera, Facultad, Campus).


File Paths: Scripts assume CSVs are located at C:\Users\Administrator\Downloads\final\. Update paths in scripts if needed.
Server Configuration: The domain should be suikacorp.com. Shared folders are created on the local C: drive (e.g., C:\Profile_UPB and C:\Home_UPB).

Note: Ensure the server has sufficient disk space for shared folders. Back up your Active Directory before running these scripts.
Installation

Clone the repository:
textgit clone https://github.com/yourusername/your-repo-name.git

Place the required CSV files (Usuarios1.csv and Carreras1.csv) in the specified path or update the script variables accordingly.
Open PowerShell as Administrator.
Navigate to the repository directory.
Ensure the ActiveDirectory module is available (it comes with RSAT tools).

Usage
1. Master Script: All.ps1
This is the entry point for creating the entire structure and users automatically.

Purpose: Verifies script existence, then runs CreacionOU's&RecursosCompartidos.ps1 followed by CreacionUsuarios.ps1.
Execution:
text.\All.ps1

Output: Console logs showing progress, successes, and any errors.

2. OU and Shared Resources Creation: CreacionOU's&RecursosCompartidos.ps1

Purpose: Creates OUs for campuses, faculties, and careers; creates groups; sets up shared folders for profiles and home directories with permissions.
Execution:
text.\CreacionOU's&RecursosCompartidos.ps1

Dependencies: Requires Carreras1.csv.
Notes: Shared paths are \\amadeus\Profile_UPB$ and \\amadeus\Home_UPB$ (assuming the server name is amadeus – update if different).

3. User Creation: CreacionUsuarios.ps1

Purpose: Creates AD users from Usuarios1.csv, generates unique usernames (e.g., career prefix + name parts + timestamp), assigns to OUs/groups, sets emails, descriptions, home directories, and profiles.
Execution:
text.\CreacionUsuarios.ps1

Dependencies: Requires Usuarios1.csv and Carreras1.csv. OUs and groups must exist (run the OU script first).
Username Format: e.g., ingjoh1234 (3-letter career sigla + 4-letter name part + 4-digit milliseconds).
Default Password: Pass123 (users must change on first logon).

4. Reset to Default: RestaurarPordefecto.ps1

Purpose: Deletes all created users (matching patterns from CSV), OUs, groups, shared folders, and SMB shares.
Execution:
text.\RestaurarPordefecto.ps1

Warning: This is destructive! Use only for testing or cleanup. It searches for users by username patterns and removes everything under OU=UPB and OU=UPB_users.

File Structure

All.ps1: Master script for sequential execution.
CreacionOU's&RecursosCompartidos.ps1: Handles OUs, groups, and shared resources.
CreacionUsuarios.ps1: Handles user creation and group assignments.
RestaurarPordefecto.ps1: Cleanup script to remove all changes.
(CSVs not included – provide your own based on the format described.)

Troubleshooting

Errors in User Creation: Check if OUs/groups exist. Ensure CSV encoding is UTF-8.
Permission Issues: Run scripts as Domain Admin. Verify NTFS
5,9sInterrumpido# Windows-server-scripts-automatization
OU's creation and Clients and Shared resources
 
dame todo elReadme en un cuadro de codigo para copiarlo y pegarlomarkdown# Active Directory User Management Scripts for UPB

This repository contains a set of PowerShell scripts designed to automate the management of users, organizational units (OUs), groups, and shared resources in an Active Directory environment for the Universidad Privada Boliviana (UPB). The scripts are tailored for creating student and professor accounts based on CSV data, setting up directory structures, and configuring roaming profiles and home directories.

These scripts are intended for system administrators managing an educational domain (e.g., `suikacorp.com`). They handle bulk operations efficiently but should be used with caution as they modify Active Directory objects and file shares.

## Features

- **OU and Group Creation**: Automatically builds a hierarchical OU structure based on campuses, faculties, and careers from a CSV file. Creates security groups for students and professors per career and campus.
- **User Creation**: Generates unique usernames and emails for users (students and professors) from a user CSV. Assigns them to appropriate OUs and groups, sets up home directories and roaming profiles.
- **Shared Resources**: Configures shared folders for home directories and profiles with appropriate NTFS and SMB permissions.
- **Reset Script**: A cleanup script to delete all created users, OUs, groups, and shared resources, restoring the environment to a default state.
- **Master Script**: Orchestrates the execution of the creation scripts in sequence.

## Prerequisites

- **Operating System**: Windows Server with Active Directory Domain Services (AD DS) installed.
- **PowerShell Version**: PowerShell 5.1 or later.
- **Modules**: `ActiveDirectory` module (imported automatically in scripts).
- **Permissions**: Run as a Domain Administrator.
- **CSV Files**:
  - `Usuarios1.csv`: Contains user data (columns: Codigo, Apellido, Nombre, Carrera, Facultad, Campus, Rol, Celular, FechaNacimiento, AnioIngreso).
  - `Carreras1.csv`: Contains career data (columns: Sigla, Carrera, Facultad, Campus).
- **File Paths**: Scripts assume CSVs are located at `C:\Users\Administrator\Downloads\final\`. Update paths in scripts if needed.
- **Server Configuration**: The domain should be `suikacorp.com`. Shared folders are created on the local C: drive (e.g., `C:\Profile_UPB` and `C:\Home_UPB`).

**Note**: Ensure the server has sufficient disk space for shared folders. Back up your Active Directory before running these scripts.

## Installation

1. Clone the repository:
git clone https://github.com/yourusername/your-repo-name.git
text2. Place the required CSV files (`Usuarios1.csv` and `Carreras1.csv`) in the specified path or update the script variables accordingly.
3. Open PowerShell as Administrator.
4. Navigate to the repository directory.
5. Ensure the `ActiveDirectory` module is available (it comes with RSAT tools).

## Usage

### 1. Master Script: All.ps1
This is the entry point for creating the entire structure and users automatically.

- **Purpose**: Verifies script existence, then runs `CreacionOU's&RecursosCompartidos.ps1` followed by `CreacionUsuarios.ps1`.
- **Execution**:
.\All.ps1
text- **Output**: Console logs showing progress, successes, and any errors.

### 2. OU and Shared Resources Creation: CreacionOU's&RecursosCompartidos.ps1
- **Purpose**: Creates OUs for campuses, faculties, and careers; creates groups; sets up shared folders for profiles and home directories with permissions.
- **Execution**:
.\CreacionOU's&RecursosCompartidos.ps1
text- **Dependencies**: Requires `Carreras1.csv`.
- **Notes**: Shared paths are `\\amadeus\Profile_UPB$` and `\\amadeus\Home_UPB$` (assuming the server name is `amadeus` – update if different).

### 3. User Creation: CreacionUsuarios.ps1
- **Purpose**: Creates AD users from `Usuarios1.csv`, generates unique usernames (e.g., career prefix + name parts + timestamp), assigns to OUs/groups, sets emails, descriptions, home directories, and profiles.
- **Execution**:
.\CreacionUsuarios.ps1
- **Dependencies**: Requires `Usuarios1.csv` and `Carreras1.csv`. OUs and groups must exist (run the OU script first).
- **Username Format**: e.g., `ingjoh1234` (3-letter career sigla + 4-letter name part + 4-digit milliseconds).
- **Default Password**: `Pass123` (users must change on first logon).

### 4. Reset to Default: RestaurarPordefecto.ps1
- **Purpose**: Deletes all created users (matching patterns from CSV), OUs, groups, shared folders, and SMB shares.
- **Execution**:
.\RestaurarPordefecto.ps1
- **Warning**: This is destructive! Use only for testing or cleanup. It searches for users by username patterns and removes everything under `OU=UPB` and `OU=UPB_users`.

## File Structure

- `All.ps1`: Master script for sequential execution.
- `CreacionOU's&RecursosCompartidos.ps1`: Handles OUs, groups, and shared resources.
- `CreacionUsuarios.ps1`: Handles user creation and group assignments.
- `RestaurarPordefecto.ps1`: Cleanup script to remove all changes.
- (CSVs not included – provide your own based on the format described.)

## Troubleshooting

- **Errors in User Creation**: Check if OUs/groups exist. Ensure CSV encoding is UTF-8.
- **Permission Issues**: Run scripts as Domain Admin. Verify NTFS/SMB permissions if shares don't work.
- **Username Conflicts**: The script uses timestamps for uniqueness; if issues persist, check AD for duplicates.
- **Shared Folder Access**: Test UNC paths after creation. Ensure the server is accessible on the network.

## Contributing

Contributions are welcome! Please fork the repository and submit pull requests for improvements, bug fixes, or additional features.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contact

For questions or support, open an issue in the repository.
