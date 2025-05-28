# 🛠️ AppInstaller

A **very simple PowerShell script** that checks for and installs programs using [Chocolatey](https://chocolatey.org/).

> ⚠️ _**Disclaimer:** This project is mainly intended for my private use. It is not designed or maintained as a general-purpose solution. I will **not** be accepting pull requests or issues. Please feel free to fork or adapt the script for your own needs, but official support or contributions will not be provided._

> 💡 _**Intended Use:** This script is primarily designed for quickly setting up fresh installs of Windows or new PCs._

---

## 🚀 Features

- Checks if specified programs are installed
- Installs missing programs automatically via Chocolatey
- **Auto-update:** Always fetches and runs the latest version of the script from GitHub if run locally
- Interactive selection for browsers, VPNs, and optional tools
- Easy to customize for your own needs

---

## 📦 Requirements

- [PowerShell](https://docs.microsoft.com/en-us/powershell/)
- [Chocolatey](https://chocolatey.org/install) (will be installed if not present)

---

## 📝 Usage

1. **Clone or download this repository.**
2. **Open PowerShell as Administrator.**
3. **Run the script:**

   ```powershell
   .\AppInstaller.ps1
   ```

   **Or run directly from GitHub (no download needed):**

   ```powershell
   irm https://raw.githubusercontent.com/DeisDev/AppInstaller/main/appinstaller.ps1 | iex
   ```

4. **Follow the prompts.**

---

## 🛠️ Customization

Edit the script to add or remove programs as needed.

---

## 📋 Supported Programs

The script currently checks for and can install the following programs:

**Text Editors:**
- Notepad++

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

**Gaming:**
- Steam
- Epic Games Launcher
- Prism Launcher

**Media:**
- VLC

**Utilities:**
- 7zip
- TranslucentTB
- Display Driver Uninstaller (DDU)

**VPNs:**
  - NordVPN
  - ProtonVPN
  - WireGuard
  - OpenVPN
  - OpenVPN Connect
  - ExpressVPN
  - Mullvad

**Extras:**
- EA App
- GOG Galaxy
- Rockstar Games Launcher
- Ubisoft Connect
- Dolphin Emulator

---

## 📄 License

Apache 2.0 License.

---
