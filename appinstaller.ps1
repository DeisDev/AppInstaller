Write-Host "=============================================" -ForegroundColor DarkGray
Write-Host "AppInstaller by DeisDev" -ForegroundColor Cyan
Write-Host "v0.2.3" -ForegroundColor DarkGray
Write-Host "Apache License 2.0 - https://www.apache.org/licenses/LICENSE-2.0" -ForegroundColor DarkGray
Write-Host "=============================================" -ForegroundColor DarkGray

# Install-Apps-With-Choco.ps1
# PowerShell script to install selected applications, pulling latest script from GitHub on each run.

# --- Admin check section ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "`nThis script must be run as Administrator. Please right-click PowerShell and select 'Run as administrator'." -ForegroundColor Red
    exit 1
}
# --- End admin check section ---

# --- Self-updating section ---
$repoRawUrl = "https://raw.githubusercontent.com/DeisDev/AppInstaller/main/appinstaller.ps1"
$localScript = $MyInvocation.MyCommand.Definition

# Only run self-update if script is running from a file
if (Test-Path $localScript) {
    try {
        $remoteScript = Invoke-WebRequest -Uri $repoRawUrl -UseBasicParsing
        if ($remoteScript.StatusCode -eq 200) {
            $remoteHash = (Get-FileHash -InputStream ([System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($remoteScript.Content))) -Algorithm SHA256).Hash
            $localHash = (Get-FileHash $localScript -Algorithm SHA256).Hash
            if ($remoteHash -ne $localHash) {
                Write-Host "`nA new version of this script is available. Downloading and re-running..." -ForegroundColor Cyan
                $tempScript = [System.IO.Path]::GetTempFileName() + ".ps1"
                [System.IO.File]::WriteAllText($tempScript, $remoteScript.Content)
                & powershell -ExecutionPolicy Bypass -File $tempScript
                exit $LASTEXITCODE
            }
        }
    } catch {
        Write-Host "Unable to check for script updates: $_" -ForegroundColor Yellow
    }
}
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
            "C:\Program Files\Google\Chrome\Application\chrome.exe",
            "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
        )
    },
    @{
        Name = "Brave"
        ChocoName = "brave"
        Paths = @(
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
        Write-Host "C. Cancel and go back"
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
    Write-Host "`nPress any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
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
    Write-Host "`nPress any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 0
}

# Step 4: Install missing programs
foreach ($prog in $toInstall) {
    Write-Host "`nInstalling $($prog.Name)..."
    choco install $($prog.ChocoName) -y
}

Write-Host "`nInstallation complete!" -ForegroundColor Green
Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")