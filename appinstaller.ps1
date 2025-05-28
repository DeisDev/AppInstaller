$scriptVersion = "v0.3.4a"
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
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
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
        Name = "Steam"
        ChocoName = "steam"
        Paths = @(
            "C:\Program Files (x86)\Steam\steam.exe"
        )
    },
    @{
        Name = "Discord"
        ChocoName = "discord"
        Paths = @(
            "$env:LOCALAPPDATA\Discord\Update.exe",
            "C:\Program Files\Discord\Update.exe"
        )
    },
    @{
        Name = "Prism Launcher"
        ChocoName = "prismlauncher"
        Paths = @(
            "C:\Program Files\Prism Launcher\prismlauncher.exe",
            "C:\Program Files (x86)\Prism Launcher\prismlauncher.exe",
            "C:\Users\$env:USERNAME\AppData\Local\Programs\PrismLauncher\prismlauncher.exe"
        )
    },
    @{
        Name = "VLC"
        ChocoName = "vlc"
        Paths = @(
            "C:\Program Files\VideoLAN\VLC\vlc.exe",
            "C:\Program Files (x86)\VideoLAN\VLC\vlc.exe"
        )
    },
    @{
        Name = "Epic Games Launcher"
        ChocoName = "epicgameslauncher"
        Paths = @(
            "C:\Program Files (x86)\Epic Games\Launcher\Portal\Binaries\Win32\EpicGamesLauncher.exe",
            "C:\Program Files\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe"
        )
    },
    @{
        Name = "TranslucentTB"
        ChocoName = "translucenttb"
        Paths = @(
            "$env:LOCALAPPDATA\Microsoft\WindowsApps\TranslucentTB.exe",
            "C:\Program Files\TranslucentTB\TranslucentTB.exe",
            "C:\Program Files (x86)\TranslucentTB\TranslucentTB.exe",
            "C:\Program Files\WindowsApps\28017CharlesMilette.TranslucentTB_2025.1.0.0_x64__v826wp6bftszj\TranslucentTB.exe"
        )
    },
    @{
        Name = "7zip"
        ChocoName = "7zip"
        Paths = @(
            "C:\Program Files\7-Zip\7zFM.exe",
            "C:\Program Files (x86)\7-Zip\7zFM.exe"
        )
    }
)

# --- Web browsers definitions ---
$webBrowsers = @(
    @{
        Name = "Edge"
        ChocoName = "microsoft-edge"
        Paths = @(
            "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
            "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
        )
    },
    @{
        Name = "Chrome"
        ChocoName = "googlechrome"
        Paths = @(
            "C:\Users\$env:USERNAME\AppData\Local\Google\Chrome\Application\chrome.exe",
            "C:\Program Files\Google\Chrome\Application\chrome.exe",
            "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
        )
    },
    @{
        Name = "Brave"
        ChocoName = "brave"
        Paths = @(
            "C:\Users\$env:USERNAME\AppData\Local\BraveSoftware\Brave-Browser\Application\brave.exe",
            "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe",
            "C:\Program Files (x86)\BraveSoftware\Brave-Browser\Application\brave.exe"
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
        Name = "Opera GX"
        ChocoName = "opera-gx"
        Paths = @(
            "C:\Users\$env:USERNAME\AppData\Local\Programs\Opera GX\opera.exe"
        )
    },
    @{
        Name = "Opera"
        ChocoName = "opera"
        Paths = @(
            "C:\Users\$env:USERNAME\AppData\Local\Programs\Opera\opera.exe"
        )
    },
    @{
        Name = "LibreWolf"
        ChocoName = "librewolf"
        Paths = @(
            "C:\Program Files\LibreWolf\librewolf.exe",
            "C:\Program Files (x86)\LibreWolf\librewolf.exe"
        )
    },
    @{
        Name = "Chromium"
        ChocoName = "chromium"
        Paths = @(
            "C:\Program Files\Chromium\Application\chrome.exe",
            "C:\Program Files (x86)\Chromium\Application\chrome.exe"
        )
    },
    @{
        Name = "Tor Browser"
        ChocoName = "tor-browser"
        Paths = @(
            "C:\Program Files\Tor Browser\Browser\firefox.exe",
            "C:\Program Files (x86)\Tor Browser\Browser\firefox.exe",
            "C:\Users\$env:USERNAME\Desktop\Tor Browser\Browser\firefox.exe"
        )
    }
)
# --- End web browsers definitions ---

# --- DDU definition ---
$dduProgram = @{
    Name = "Display Driver Uninstaller (DDU)"
    ChocoName = "display-driver-uninstaller"
    Paths = @(
        "C:\Program Files\Display Driver Uninstaller\Display Driver Uninstaller.exe",
        "C:\Program Files (x86)\Display Driver Uninstaller\Display Driver Uninstaller.exe"
    )
}
# --- End DDU definition ---

# --- VPN definitions ---
$vpnPrograms = @(
    @{
        Name = "NordVPN"
        ChocoName = "nordvpn"
        Paths = @(
            "C:\Program Files\NordVPN\NordVPN.exe",
            "C:\Program Files (x86)\NordVPN\NordVPN.exe"
        )
    },
    @{
        Name = "ProtonVPN"
        ChocoName = "protonvpn"
        Paths = @(
            "C:\Program Files\Proton Technologies\ProtonVPN\ProtonVPN.exe",
            "C:\Program Files (x86)\Proton Technologies\ProtonVPN\ProtonVPN.exe"
        )
    },
    @{
        Name = "WireGuard"
        ChocoName = "wireguard"
        Paths = @(
            "C:\Program Files\WireGuard\wireguard.exe",
            "C:\Program Files (x86)\WireGuard\wireguard.exe"
        )
    },
    @{
        Name = "OpenVPN"
        ChocoName = "openvpn"
        Paths = @(
            "C:\Program Files\OpenVPN\bin\openvpn.exe",
            "C:\Program Files (x86)\OpenVPN\bin\openvpn.exe"
        )
    },
    @{
        Name = "OpenVPN Connect"
        ChocoName = "openvpn-connect"
        Paths = @(
            "C:\Program Files\OpenVPN Connect\OpenVPNConnect.exe",
            "C:\Program Files (x86)\OpenVPN Connect\OpenVPNConnect.exe"
        )
    },
    @{
        Name = "ExpressVPN"
        ChocoName = "expressvpn"
        Paths = @(
            "C:\Program Files (x86)\ExpressVPN\expressvpn-ui\ExpressVPN.exe",
            "C:\Program Files\ExpressVPN\expressvpn-ui\ExpressVPN.exe"
        )
    },
    @{
        Name = "Mullvad"
        ChocoName = "mullvad-vpn"
        Paths = @(
            "C:\Program Files\Mullvad VPN\mullvad.exe",
            "C:\Program Files (x86)\Mullvad VPN\mullvad.exe"
        )
    }
)
# --- End VPN definitions ---

# --- Extras definitions ---
$extrasPrograms = @(
    @{
        Name = "EA App"
        ChocoName = "ea-app"
        Paths = @(
            "C:\Program Files\Electronic Arts\EA Desktop\EA Desktop.exe",
            "C:\Program Files\EA Games\EA Desktop\EA Desktop.exe"
        )
    },
    @{
        Name = "GOG Galaxy"
        ChocoName = "gog-galaxy"
        Paths = @(
            "C:\Program Files (x86)\GOG Galaxy\GalaxyClient.exe",
            "C:\Program Files\GOG Galaxy\GalaxyClient.exe"
        )
    },
    @{
        Name = "Rockstar Games Launcher"
        ChocoName = "rockstar-launcher"
        Paths = @(
            "C:\Program Files\Rockstar Games\Launcher\Launcher.exe",
            "C:\Program Files (x86)\Rockstar Games\Launcher\Launcher.exe"
        )
    },
    @{
        Name = "Ubisoft Connect"
        ChocoName = "ubisoft-connect"
        Paths = @(
            "C:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher\UbisoftConnect.exe",
            "C:\Program Files\Ubisoft\Ubisoft Game Launcher\UbisoftConnect.exe"
        )
    },
    @{
        Name = "Dolphin Emulator"
        ChocoName = "dolphin"
        Paths = @(
            "C:\Program Files\Dolphin\Dolphin.exe",
            "C:\Program Files (x86)\Dolphin\Dolphin.exe"
        )
    }
)
# --- End Extras definitions ---

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

# --- Prompt for web browser installation ---
Write-Host "`nWould you like to install a web browser?" -ForegroundColor Cyan
do {
    $browserPrompt = Read-Host "Install a web browser? (Y/N)"
} while ($browserPrompt -notmatch '^(Y|N)$')

if ($browserPrompt -eq 'Y') {
    :browserSelectLoop while ($true) {
        Write-Host "`nAvailable browsers:" -ForegroundColor Cyan
        for ($i = 0; $i -lt $webBrowsers.Count; $i++) {
            Write-Host "$($i+1). $($webBrowsers[$i].Name)"
        }
        $browserChoice = Read-Host "Enter the number of the browser you want to install, or 'C' to cancel"
        if ($browserChoice -match '^[Cc]$') {
            # Go back to the previous prompt
            do {
                $browserPrompt = Read-Host "Install a web browser? (Y/N)"
            } while ($browserPrompt -notmatch '^(Y|N)$')
            if ($browserPrompt -eq 'Y') {
                continue browserSelectLoop
            } else {
                break
            }
        }
        $valid = $browserChoice -match '^\d+$' -and [int]$browserChoice -ge 1 -and [int]$browserChoice -le $webBrowsers.Count
        if ($valid) {
            $selectedBrowser = $webBrowsers[[int]$browserChoice - 1]
            $programs += $selectedBrowser
            Write-Host "`n$($selectedBrowser.Name) will be included in the installation list." -ForegroundColor Green
            break
        }
    }
}
# --- End browser prompt ---

# --- Prompt for DDU installation ---
Write-Host "`nWould you like to install Display Driver Uninstaller (DDU)?" -ForegroundColor Cyan
do {
    $dduPrompt = Read-Host "Install DDU? (Y/N)"
} while ($dduPrompt -notmatch '^(Y|N)$')

if ($dduPrompt -eq 'Y') {
    $programs += $dduProgram
    Write-Host "`nDisplay Driver Uninstaller (DDU) will be included in the installation list." -ForegroundColor Green
}
# --- End DDU prompt ---

# --- Prompt for VPN installation ---
Write-Host "`nWould you like to install a VPN?" -ForegroundColor Cyan
do {
    $vpnPrompt = Read-Host "Install a VPN? (Y/N)"
} while ($vpnPrompt -notmatch '^(Y|N)$')

if ($vpnPrompt -eq 'Y') {
    :vpnSelectLoop while ($true) {
        Write-Host "`nAvailable VPNs:" -ForegroundColor Cyan
        for ($i = 0; $i -lt $vpnPrograms.Count; $i++) {
            Write-Host "$($i+1). $($vpnPrograms[$i].Name)"
        }
        $vpnChoice = Read-Host "Enter the number of the VPN you want to install, or 'C' to cancel"
        if ($vpnChoice -match '^[Cc]$') {
            # Go back to the previous prompt
            do {
                $vpnPrompt = Read-Host "Install a VPN? (Y/N)"
            } while ($vpnPrompt -notmatch '^(Y|N)$')
            if ($vpnPrompt -eq 'Y') {
                continue vpnSelectLoop
            } else {
                break
            }
        }
        $validVpn = $vpnChoice -match '^\d+$' -and [int]$vpnChoice -ge 1 -and [int]$vpnChoice -le $vpnPrograms.Count
        if ($validVpn) {
            $selectedVpn = $vpnPrograms[[int]$vpnChoice - 1]
            $programs += $selectedVpn
            Write-Host "`n$($selectedVpn.Name) will be included in the installation list." -ForegroundColor Green
            break
        }
    }
}
# --- End VPN prompt ---

# --- Prompt for Extras installation ---
Write-Host "`nWould you like to install any Extras (EA App, GOG Galaxy, Rockstar Games Launcher, Ubisoft Connect, Dolphin Emulator)?" -ForegroundColor Cyan
do {
    $extrasPrompt = Read-Host "Install Extras? (Y/N)"
} while ($extrasPrompt -notmatch '^(Y|N)$')

if ($extrasPrompt -eq 'Y') {
    :extrasSelectLoop while ($true) {
        Write-Host "`nAvailable Extras:" -ForegroundColor Cyan
        for ($i = 0; $i -lt $extrasPrograms.Count; $i++) {
            Write-Host "$($i+1). $($extrasPrograms[$i].Name)"
        }
        $extrasChoice = Read-Host "Enter the number of the Extra you want to install, or 'A' for all, or 'C' to cancel"
        if ($extrasChoice -match '^[Cc]$') {
            # Go back to the previous prompt
            do {
                $extrasPrompt = Read-Host "Install Extras? (Y/N)"
            } while ($extrasPrompt -notmatch '^(Y|N)$')
            if ($extrasPrompt -eq 'Y') {
                continue extrasSelectLoop
            } else {
                break
            }
        }
        if ($extrasChoice -match '^[Aa]$') {
            foreach ($extra in $extrasPrograms) {
                $programs += $extra
            }
            Write-Host "`nAll Extras will be included in the installation list." -ForegroundColor Green
            break
        }
        $validExtras = $extrasChoice -match '^\d+$' -and [int]$extrasChoice -ge 1 -and [int]$extrasChoice -le $extrasPrograms.Count
        if ($validExtras) {
            $selectedExtra = $extrasPrograms[[int]$extrasChoice - 1]
            $programs += $selectedExtra
            Write-Host "`n$($selectedExtra.Name) will be included in the installation list." -ForegroundColor Green
            break
        }
    }
}
# --- End Extras prompt ---

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
    Write-Host "`nPress Enter to exit..."
    Read-Host | Out-Null
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