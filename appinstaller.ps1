$scriptVersion = "v0.3.6a"
Write-Host "=============================================" -ForegroundColor DarkGray
Write-Host "AppInstaller by DeisDev" -ForegroundColor Cyan
Write-Host $scriptVersion -ForegroundColor DarkGray
Write-Host "Apache License 2.0 - https://www.apache.org/licenses/LICENSE-2.0" -ForegroundColor DarkGray

# --- System Information ---
$os = Get-CimInstance Win32_OperatingSystem
$winVer = $os.Caption + " " + $os.Version
$arch = if ([Environment]::Is64BitOperatingSystem) { "64-bit" } else { "32-bit" }
$netAdapters = Get-NetConnectionProfile -ErrorAction SilentlyContinue
if ($netAdapters) {
    $connType = ($netAdapters | Where-Object { $_.IPv4Connectivity -eq "Internet" } | Select-Object -First 1).NetworkCategory
    if (-not $connType) { $connType = $netAdapters[0].NetworkCategory }
} else {
    $connType = "Unknown"
}
Write-Host ("Windows Version: $winVer") -ForegroundColor DarkGray
Write-Host ("Architecture: $arch") -ForegroundColor DarkGray
Write-Host ("Connection Type: $connType") -ForegroundColor DarkGray
# --- End System Information ---

Write-Host "=============================================" -ForegroundColor DarkGray

# AppInstaller.ps1
# PowerShell script to install selected applications, pulling latest script from GitHub on each run.

# --- Admin check section ---
$devEnv = $false
# Check for VSCode environment variable
if ($env:TERM_PROGRAM -eq "vscode") {
    $devEnv = $true
    Write-Host "[DEV MODE] Detected VSCode environment (`$env:TERM_PROGRAM = vscode`)" -ForegroundColor Yellow
} else {
    # Check if parent process is Code.exe (VSCode)
    try {
        $parent = Get-CimInstance Win32_Process -Filter "ProcessId=$((Get-CimInstance Win32_Process -Filter "ProcessId=$PID").ParentProcessId)"
        if ($parent.Name -like "Code.exe") {
            $devEnv = $true
            Write-Host "[DEV MODE] Detected VSCode parent process: $($parent.Name) (PID: $($parent.ProcessId))" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[DEV MODE] Could not determine parent process for development environment detection." -ForegroundColor DarkGray
    }
}

if ($devEnv) {
    Write-Host "[DEV MODE] Running in development environment. Bypassing administrator check." -ForegroundColor Yellow
    Write-Host "[DEV MODE] Current PID: $PID" -ForegroundColor DarkGray
}

if (-not $devEnv -and -not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "`nThis script must be run as Administrator. Please right-click PowerShell and select 'Run as administrator'." -ForegroundColor Red
    exit 1
}
# --- End admin check section ---

# --- Self-updating section ---
function Get-VersionStringFromContent {
    param($content)
    if ($content -match '\$scriptVersion\s*=\s*"(.*?)"') {
        return $matches[1]
    }
    return $null
}

function Update-SelfIfNeeded {
    $repoRawUrl = "https://raw.githubusercontent.com/DeisDev/AppInstaller/main/appinstaller.ps1"
    $localScript = $MyInvocation.MyCommand.Definition

    # Only update if running from a file
    if (-not (Test-Path $localScript -PathType Leaf)) {
        return
    }

    try {
        $remoteScript = Invoke-WebRequest -Uri $repoRawUrl -UseBasicParsing -ErrorAction Stop
        if ($remoteScript.StatusCode -ne 200) {
            Write-Host "Could not check for updates (HTTP $($remoteScript.StatusCode))." -ForegroundColor Yellow
            return
        }
        $remoteContent = $remoteScript.Content
        $remoteVersion = Get-VersionStringFromContent $remoteContent

        try {
            $localContent = Get-Content $localScript -Raw
        } catch {
            $localContent = Get-Content $localScript | Out-String
        }
        $localVersion = Get-VersionStringFromContent $localContent

        if ($remoteVersion -and $localVersion) {
            if ($remoteVersion -ne $localVersion) {
                Write-Host "`nA new version ($remoteVersion) is available. Updating..." -ForegroundColor Cyan
                $tempScript = [System.IO.Path]::GetTempFileName() + ".ps1"
                [System.IO.File]::WriteAllText($tempScript, $remoteContent)
                & powershell -ExecutionPolicy Bypass -File $tempScript
                exit $LASTEXITCODE
            } else {
                Write-Host "Script is up to date." -ForegroundColor Green
            }
        } else {
            # Fallback to hash comparison if version string missing
            $remoteHash = (Get-FileHash -InputStream ([System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($remoteContent))) -Algorithm SHA256).Hash
            $localHash = (Get-FileHash $localScript -Algorithm SHA256).Hash
            if ($remoteHash -ne $localHash) {
                Write-Host "`nA new version is available (hash mismatch). Updating..." -ForegroundColor Cyan
                $tempScript = [System.IO.Path]::GetTempFileName() + ".ps1"
                [System.IO.File]::WriteAllText($tempScript, $remoteContent)
                & powershell -ExecutionPolicy Bypass -File $tempScript
                exit $LASTEXITCODE
            } else {
                Write-Host "Script is up to date." -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "Unable to check for script updates: $_" -ForegroundColor Yellow
    }
}

Update-SelfIfNeeded
# --- End self-updating section ---

# --- Software Definitions ---

# Browsers
$browsers = @(
    @{ Name = "Edge";         ChocoName = "microsoft-edge"; Paths = @("C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe", "C:\Program Files\Microsoft\Edge\Application\msedge.exe") },
    @{ Name = "Chrome";       ChocoName = "googlechrome";   Paths = @("C:\Users\$env:USERNAME\AppData\Local\Google\Chrome\Application\chrome.exe", "C:\Program Files\Google\Chrome\Application\chrome.exe", "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe") },
    @{ Name = "Brave";        ChocoName = "brave";          Paths = @("C:\Users\$env:USERNAME\AppData\Local\BraveSoftware\Brave-Browser\Application\brave.exe", "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe", "C:\Program Files (x86)\BraveSoftware\Brave-Browser\Application\brave.exe") },
    @{ Name = "Firefox";      ChocoName = "firefox";        Paths = @("C:\Program Files\Mozilla Firefox\firefox.exe", "C:\Program Files (x86)\Mozilla Firefox\firefox.exe") },
    @{ Name = "Opera GX";     ChocoName = "opera-gx";       Paths = @("C:\Users\$env:USERNAME\AppData\Local\Programs\Opera GX\opera.exe") },
    @{ Name = "Opera";        ChocoName = "opera";          Paths = @("C:\Users\$env:USERNAME\AppData\Local\Programs\Opera\opera.exe") },
    @{ Name = "LibreWolf";    ChocoName = "librewolf";      Paths = @("C:\Program Files\LibreWolf\librewolf.exe", "C:\Program Files (x86)\LibreWolf\librewolf.exe") },
    @{ Name = "Chromium";     ChocoName = "chromium";       Paths = @("C:\Program Files\Chromium\Application\chrome.exe", "C:\Program Files (x86)\Chromium\Application\chrome.exe") },
    @{ Name = "Tor Browser";  ChocoName = "tor-browser";    Paths = @("C:\Program Files\Tor Browser\Browser\firefox.exe", "C:\Program Files (x86)\Tor Browser\Browser\firefox.exe", "C:\Users\$env:USERNAME\Desktop\Tor Browser\Browser\firefox.exe") }
)

# Text Editors
$textEditors = @(
    @{ Name = "Notepad++";     ChocoName = "notepadplusplus"; Paths = @("C:\Program Files\Notepad++\notepad++.exe", "C:\Program Files (x86)\Notepad++\notepad++.exe") },
    @{ Name = "Sublime Text 3";ChocoName = "sublimetext3";    Paths = @("C:\Program Files\Sublime Text 3\sublime_text.exe", "C:\Program Files (x86)\Sublime Text 3\sublime_text.exe") },
    @{ Name = "Neovim";        ChocoName = "neovim";           Paths = @("C:\Program Files\Neovim\bin\nvim.exe", "C:\Program Files (x86)\Neovim\bin\nvim.exe") }
)

# Game Launchers
$gameLaunchers = @(
    @{ Name = "Steam";             ChocoName = "steam";              Paths = @("C:\Program Files (x86)\Steam\steam.exe") },
    @{ Name = "Epic Games";        ChocoName = "epicgameslauncher";  Paths = @("C:\Program Files (x86)\Epic Games\Launcher\Portal\Binaries\Win32\EpicGamesLauncher.exe", "C:\Program Files\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe") },
    @{ Name = "EA App";            ChocoName = "ea-app";             Paths = @("C:\Program Files\Electronic Arts\EA Desktop\EA Desktop.exe", "C:\Program Files\EA Games\EA Desktop\EA Desktop.exe", "C:\Users\$env:USERNAME\AppData\Local\EADesktop\EA Desktop.exe", "C:\Users\$env:USERNAME\AppData\Roaming\EADesktop\EA Desktop.exe", "C:\Program Files\Electronic Arts\EA Desktop\EA Desktop\EADesktop.exe") },
    @{ Name = "GOG Galaxy";        ChocoName = "gog-galaxy";         Paths = @("C:\Program Files (x86)\GOG Galaxy\GalaxyClient.exe", "C:\Program Files\GOG Galaxy\GalaxyClient.exe") },
    @{ Name = "Rockstar Launcher"; ChocoName = "rockstar-launcher";  Paths = @("C:\Program Files\Rockstar Games\Launcher\Launcher.exe", "C:\Program Files (x86)\Rockstar Games\Launcher\Launcher.exe") },
    @{ Name = "Ubisoft Connect";   ChocoName = "ubisoft-connect";    Paths = @("C:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher\UbisoftConnect.exe", "C:\Program Files\Ubisoft\Ubisoft Game Launcher\UbisoftConnect.exe") },
    @{ Name = "Prism Launcher";    ChocoName = "prismlauncher";      Paths = @("C:\Program Files\Prism Launcher\prismlauncher.exe", "C:\Program Files (x86)\Prism Launcher\prismlauncher.exe", "C:\Users\$env:USERNAME\AppData\Local\Programs\PrismLauncher\prismlauncher.exe") }
)

# Utilities
$utilities = @(
    @{ Name = "7zip";          ChocoName = "7zip";            Paths = @("C:\Program Files\7-Zip\7zFM.exe", "C:\Program Files (x86)\7-Zip\7zFM.exe") },
    @{ Name = "WinRAR";        ChocoName = "winrar";          Paths = @("C:\Program Files\WinRAR\WinRAR.exe", "C:\Program Files (x86)\WinRAR\WinRAR.exe") },
    @{ Name = "Bulk Crap Uninstaller"; ChocoName = "bulk-crap-uninstaller"; Paths = @("C:\Program Files\Bulk Crap Uninstaller\BCUninstaller.exe", "C:\Program Files (x86)\Bulk Crap Uninstaller\BCUninstaller.exe") },
    @{ Name = "GIMP";          ChocoName = "gimp";            Paths = @("C:\Program Files\GIMP 2\bin\gimp-2.10.exe", "C:\Program Files\GIMP 2\bin\gimp-2.8.exe", "C:\Program Files (x86)\GIMP 2\bin\gimp-2.10.exe") },
    @{ Name = "JDownloader2";  ChocoName = "jdownloader";     Paths = @("C:\Program Files\JDownloader\JDownloader2.exe", "C:\Program Files (x86)\JDownloader\JDownloader2.exe") },
    @{ Name = "HWInfo";        ChocoName = "hwinfo";          Paths = @("C:\Program Files\HWiNFO64\HWiNFO64.exe", "C:\Program Files (x86)\HWiNFO32\HWiNFO32.exe") },
    @{ Name = "Process Hacker";ChocoName = "processhacker";   Paths = @("C:\Program Files\Process Hacker 2\ProcessHacker.exe", "C:\Program Files (x86)\Process Hacker 2\ProcessHacker.exe") },
    @{ Name = "CrystalDiskInfo";ChocoName = "crystaldiskinfo";Paths = @("C:\Program Files\CrystalDiskInfo\DiskInfo64.exe", "C:\Program Files (x86)\CrystalDiskInfo\DiskInfo32.exe") },
    @{ Name = "GPU-Z";         ChocoName = "gpu-z";           Paths = @("C:\Program Files\GPU-Z\GPU-Z.exe", "C:\Program Files (x86)\GPU-Z\GPU-Z.exe") },
    @{ Name = "OBS Studio";    ChocoName = "obs-studio";      Paths = @("C:\Program Files\obs-studio\bin\64bit\obs64.exe", "C:\Program Files (x86)\obs-studio\bin\32bit\obs32.exe") },
    @{ Name = "TranslucentTB"; ChocoName = "translucenttb";   Paths = @("$env:LOCALAPPDATA\Microsoft\WindowsApps\TranslucentTB.exe", "C:\Program Files\TranslucentTB\TranslucentTB.exe", "C:\Program Files (x86)\TranslucentTB\TranslucentTB.exe", "C:\Program Files\WindowsApps\28017CharlesMilette.TranslucentTB_2025.1.0.0_x64__v826wp6bftszj\TranslucentTB.exe") },
    @{ Name = "Display Driver Uninstaller (DDU)"; ChocoName = "display-driver-uninstaller"; Paths = @("C:\Program Files\Display Driver Uninstaller\Display Driver Uninstaller.exe", "C:\Program Files (x86)\Display Driver Uninstaller\Display Driver Uninstaller.exe") },
    @{ Name = "VLC";           ChocoName = "vlc";             Paths = @("C:\Program Files\VideoLAN\VLC\vlc.exe", "C:\Program Files (x86)\VideoLAN\VLC\vlc.exe") }
)

# Torrents
$torrents = @(
    @{ Name = "qBittorrent"; ChocoName = "qbittorrent"; Paths = @("C:\Program Files\qBittorrent\qbittorrent.exe", "C:\Program Files (x86)\qBittorrent\qbittorrent.exe") }
)

# Benchmarks
$benchmarks = @(
    @{ Name = "FurMark"; ChocoName = "furmark"; Paths = @("C:\Program Files\Geeks3D\FurMark\FurMark.exe", "C:\Program Files (x86)\Geeks3D\FurMark\FurMark.exe") }
)

# VPNs
$vpns = @(
    @{ Name = "NordVPN";         ChocoName = "nordvpn";         Paths = @("C:\Program Files\NordVPN\NordVPN.exe", "C:\Program Files (x86)\NordVPN\NordVPN.exe") },
    @{ Name = "ProtonVPN";       ChocoName = "protonvpn";       Paths = @("C:\Program Files\Proton Technologies\ProtonVPN\ProtonVPN.exe", "C:\Program Files (x86)\Proton Technologies\ProtonVPN\ProtonVPN.exe") },
    @{ Name = "WireGuard";       ChocoName = "wireguard";       Paths = @("C:\Program Files\WireGuard\wireguard.exe", "C:\Program Files (x86)\WireGuard\wireguard.exe") },
    @{ Name = "OpenVPN";         ChocoName = "openvpn";         Paths = @("C:\Program Files\OpenVPN\bin\openvpn.exe", "C:\Program Files (x86)\OpenVPN\bin\openvpn.exe") },
    @{ Name = "OpenVPN Connect"; ChocoName = "openvpn-connect"; Paths = @("C:\Program Files\OpenVPN Connect\OpenVPNConnect.exe", "C:\Program Files (x86)\OpenVPN Connect\OpenVPNConnect.exe") },
    @{ Name = "ExpressVPN";      ChocoName = "expressvpn";      Paths = @("C:\Program Files (x86)\ExpressVPN\expressvpn-ui\ExpressVPN.exe", "C:\Program Files\ExpressVPN\expressvpn-ui\ExpressVPN.exe") },
    @{ Name = "Mullvad";         ChocoName = "mullvad-vpn";     Paths = @("C:\Program Files\Mullvad VPN\mullvad.exe", "C:\Program Files (x86)\Mullvad VPN\mullvad.exe") }
)

# Emulators
$emulators = @(
    @{ Name = "Dolphin Emulator"; ChocoName = "dolphin"; Paths = @("C:\Program Files\Dolphin\Dolphin.exe", "C:\Program Files (x86)\Dolphin\Dolphin.exe") }
)

# --- End Software Definitions ---

# --- Selection Logic ---
function Select-ProgramsFromCategory($categoryName, $programList) {
    Write-Host "`nWould you like to install any ${categoryName}?" -ForegroundColor Cyan
    do {
        $catPrompt = Read-Host "Install from ${categoryName}? (Y/N)"
    } while ($catPrompt -notmatch '^(Y|N)$')
    $selected = @()
    if ($catPrompt -eq 'Y') {
        Write-Host "`nAvailable ${categoryName}:" -ForegroundColor Cyan
        for ($i = 0; $i -lt $programList.Count; $i++) {
            Write-Host "$($i+1). $($programList[$i].Name)"
        }
        do {
            $choice = Read-Host "Enter the number(s) of the ${categoryName} you want to install (comma separated, e.g. 1,3,5), or 'C' to cancel"
            if ($choice -match '^[Cc]$') { break }
            $indices = $choice -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' }
            $valid = $indices.Count -gt 0 -and ($indices | Where-Object { ($_ -as [int]) -ge 1 -and ($_ -as [int]) -le $programList.Count }).Count -eq $indices.Count
        } while (-not $valid -and $choice -notmatch '^[Cc]$')
        if ($valid) {
            foreach ($idx in $indices) {
                $selected += $programList[[int]$idx - 1]
            }
            Write-Host "`nSelected ${categoryName}:" -ForegroundColor Green
            foreach ($prog in $selected) { Write-Host "- $($prog.Name)" }
        }
    }
    return $selected
}

$programs = @()
$programs += Select-ProgramsFromCategory "Text Editors" $textEditors
$programs += Select-ProgramsFromCategory "Web Browsers" $browsers
$programs += Select-ProgramsFromCategory "Game Launchers" $gameLaunchers
$programs += Select-ProgramsFromCategory "Utilities" $utilities
$programs += Select-ProgramsFromCategory "VPNs" $vpns
$programs += Select-ProgramsFromCategory "Emulators" $emulators
$programs += Select-ProgramsFromCategory "Torrents" $torrents
$programs += Select-ProgramsFromCategory "Benchmarks" $benchmarks

if ($programs.Count -eq 0) {
    Write-Host "`nNo programs selected for installation. Exiting." -ForegroundColor Cyan
    Write-Host "`nPress Enter to exit..."
    Read-Host | Out-Null
    exit 0
}

# Remove old, redundant definitions
# --- Web browsers definitions ---
# --- DDU definition ---
# --- VPN definitions ---
# --- Extras definitions ---

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
        $expanded = [Environment]::ExpandEnvironmentVariables($path)
        if (Test-Path $expanded) {
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
    Write-Host "`nPress Enter to exit..."
    Read-Host | Out-Null
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
    do {
        $restartChoice = Read-Host "`nType 'R' to return to the start, or press Enter to exit."
        if ($restartChoice -match '^[Rr]$') {
            & powershell -ExecutionPolicy Bypass -File $MyInvocation.MyCommand.Definition
            exit $LASTEXITCODE
        }
    } while ($restartChoice -match '^[Rr]$' -eq $false -and $restartChoice -ne "")
    exit 0
}

# Step 4: Install missing programs
foreach ($prog in $toInstall) {
    Write-Host "`nInstalling $($prog.Name)..."
    choco install $($prog.ChocoName) -y
}

Write-Host "`nInstallation complete!" -ForegroundColor Green

# Prompt to restart or exit
do {
    $restartChoice = Read-Host "`nType 'R' to return to the start, or press Enter to exit."
    if ($restartChoice -match '^[Rr]$') {
        # Re-invoke the script
        & powershell -ExecutionPolicy Bypass -File $MyInvocation.MyCommand.Definition
        exit $LASTEXITCODE
    }
} while ($restartChoice -match '^[Rr]$' -eq $false -and $restartChoice -ne "")

# If user just presses Enter, exit
exit 0