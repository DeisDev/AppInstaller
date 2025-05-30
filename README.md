# 🛠️ AppInstaller

A **simple, interactive PowerShell script** for quickly setting up a new Windows PC by checking for and installing popular programs using [Chocolatey](https://chocolatey.org/).

> [!NOTE]
> **Intended Use:**  
> Ideal for fresh Windows installs, new PCs, or quickly restoring your preferred software stack.

> [!WARNING]
> **Disclaimer:**  
> This project is primarily for my personal use. It is not designed or maintained as a general-purpose solution.  
> I do **not** accept pull requests or issues. Please feel free to fork or adapt the script for your own needs, but official support or contributions will not be provided.

---

## 🚀 Features

- **Interactive selection:** Choose which categories and programs to install (browsers, editors, utilities, VPNs, etc.)
- **Checks for existing installs:** Skips programs already present on your system
- **Self-updating:** Always fetches and runs the latest version of the script from GitHub if run locally
- **Chocolatey bootstrap:** Installs Chocolatey automatically if not already installed
- **Easy customization:** Add or remove programs by editing the script

---

## 📦 Requirements

- [PowerShell](https://docs.microsoft.com/en-us/powershell/) (Windows 10/11 recommended)
- [Chocolatey](https://chocolatey.org/install) (will be installed automatically if not present)
- **Administrator privileges** (required for installing software)

---

## 📝 Usage

> [!IMPORTANT]
> Make sure you execute the script as Administrator or else programs may fail to install. 

1. **Clone or download this repository.**
2. **Open PowerShell as Administrator.**
3. **Run the script:**

   ```powershell
   .\AppInstaller.ps1
   ```
> [!TIP]
> **You can always run the latest version of the script directly from GitHub (no download needed):**
   ```powershell
   irm https://raw.githubusercontent.com/DeisDev/AppInstaller/main/appinstaller.ps1 | iex
   ```
4. **Follow the prompts** to select and install your desired programs.

---

## 🛠️ Customization

> [!TIP]
> Adding a package to the list is very straightforward. If you do not see a package you are looking for, you can add it to the script in minutes. 


To add or remove programs, simply edit the `$browsers`, `$textEditors`, `$utilities`, etc. arrays in the script.  
Each entry defines the program name, Chocolatey package name, and common install paths for detection.

---

## 📋 Supported Programs

<details>
<summary><strong>Click to expand full list</strong></summary>

**Text Editors:**
- Notepad++
- Sublime Text 3
- Neovim
- Obsidian

**Web Browsers:**
- Edge
- Chrome
- Brave
- Firefox
- Opera GX
- Opera
- LibreWolf
- Chromium
- Tor Browser
- Vivaldi

**Game Launchers:**
- Steam
- Epic Games Launcher
- EA App
- GOG Galaxy
- Rockstar Games Launcher
- Ubisoft Connect
- Prism Launcher

**Emulators:**
- Dolphin Emulator

**Utilities:**
- 7zip
- WinRAR
- Bulk Crap Uninstaller
- GIMP
- JDownloader2
- HWInfo
- Process Hacker
- CrystalDiskInfo
- GPU-Z
- OBS Studio
- TranslucentTB
- Display Driver Uninstaller (DDU)
- VLC
- WizTree

**VPNs:**
- NordVPN
- ProtonVPN
- WireGuard
- OpenVPN
- OpenVPN Connect
- ExpressVPN
- Mullvad

**Torrents:**
- qBittorrent

**Benchmarks:**
- FurMark

</details>

---

## 📄 License

Apache 2.0 License.

---
