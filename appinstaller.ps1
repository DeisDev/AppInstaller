# Installs listed programs using Chocolatey if they are not already installed.

$programs = @(
    @{
        Name = "Notepad++"
        ChocoName = "notepadplusplus"
        Paths = @(
            "C:\Program Files\Notepad++\notepad++.exe",
            "C:\Program Files (x86)\Notepad++\notepad++.exe"
        )
    },
    @{
        Name = "Firefox"
        ChocoName = "firefox"
        Paths = @(
            "C:\Program Files\Mozilla Firefox\firefox.exe",
            "C:\Program Files (x86)\Mozilla Firefox\firefox.exe"
        )
    },
    @{
        Name = "Steam"
        ChocoName = "steam"
        Paths = @(
            "C:\Program Files (x86)\Steam\steam.exe"
        )
    }
)

function Is-ChocolateyInstalled {
    return (Get-Command choco.exe -ErrorAction SilentlyContinue) -ne $null
}

function Install-Chocolatey {
    Write-Host "`nChocolatey not found. Installing Chocolatey..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

function Is-ProgramInstalled {
    param($prog)
    # Path check
    foreach ($path in $prog.Paths) {
        if (Test-Path $path) {
            return $true
        }
    }
    # Chocolatey check
    $pkg = choco list --local-only --exact $prog.ChocoName 2>$null | Select-String "^$($prog.ChocoName) "
    if ($pkg -ne $null) {
        return $true
    }
    return $false
}

# Step 1: Ensure Chocolatey is installed
if (-not (Is-ChocolateyInstalled)) {
    Install-Chocolatey
    if (-not (Is-ChocolateyInstalled)) {
        Write-Host "Chocolatey installation failed. Exiting." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "Chocolatey is already installed."
}

# Step 2: Check for already installed programs
Write-Host "`nChecking for installed programs..."
$toInstall = @()

foreach ($prog in $programs) {
    if (Is-ProgramInstalled $prog) {
        Write-Host "$($prog.Name) is already installed." -ForegroundColor Green
    } else {
        Write-Host "$($prog.Name) is NOT installed." -ForegroundColor Yellow
        $toInstall += $prog
    }
}

if ($toInstall.Count -eq 0) {
    Write-Host "`nAll programs are already installed. Nothing to do." -ForegroundColor Cyan
    exit 0
}

# Step 3: Prompt user for installation
Write-Host "`nThe following programs will be installed:"
$toInstall | ForEach-Object { Write-Host "- $($_.Name)" }

do {
    $response = Read-Host "Do you wish to install the selected programs? (Y/N)"
} while ($response -notmatch '^(Y|N)$')

if ($response -eq 'N') {
    Write-Host "Installation aborted by user." -ForegroundColor Red
    exit 0
}

# Step 4: Install missing programs
foreach ($prog in $toInstall) {
    Write-Host "`nInstalling $($prog.Name)..."
    choco install $($prog.ChocoName) -y
}

Write-Host "`nInstallation complete!" -ForegroundColor Green