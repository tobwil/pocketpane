# PocketPane

**Your Android, right here.**

PocketPane mirrors and controls Android phones wirelessly from macOS and Windows. It wraps the proven [scrcpy](https://github.com/Genymobile/scrcpy) and Android Debug Bridge tools in a desktop UI—no terminal, cloud account, phone companion app, or cable required after pairing.

[![Latest release](https://img.shields.io/github/v/release/tobwil/pocketpane?display_name=tag&sort=semver)](https://github.com/tobwil/pocketpane/releases/latest)
[![macOS 14+](https://img.shields.io/badge/macOS-14%2B-111111?logo=apple)](https://github.com/tobwil/pocketpane/releases/latest)
[![Windows 10+](https://img.shields.io/badge/Windows-10%2B-0078D4?logo=windows&logoColor=white)](https://github.com/tobwil/pocketpane/releases/latest)
[![scrcpy 4.0](https://img.shields.io/badge/scrcpy-4.0-3DDC84?logo=android&logoColor=white)](https://github.com/Genymobile/scrcpy)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Website](https://img.shields.io/badge/website-pocketpane.app-0A84FF)](https://pocketpane.app)

![PocketPane dashboard in Light Mode](https://github.com/user-attachments/assets/fab59bf3-51be-40e2-a71a-136800febed0#gh-light-mode-only)
![PocketPane dashboard in Dark Mode](https://github.com/user-attachments/assets/fb04e6a1-e70c-4661-a681-bd8037fc358b#gh-dark-mode-only)

## Download

| Platform | Download | Package |
| --- | --- | --- |
| macOS 14+, Apple Silicon | [PocketPane 0.2.0 for macOS](https://github.com/tobwil/pocketpane/releases/download/v0.2.0/PocketPane-0.2.0-macOS-arm64.zip) | Native SwiftUI app with ADB and scrcpy included |
| Windows 10+, x64 | [PocketPane 0.2.0 for Windows](https://github.com/tobwil/pocketpane/releases/download/v0.2.0/PocketPane-0.2.0-Windows-x64.zip) | Portable folder with PocketPane.exe, ADB, and scrcpy included |

You can also browse the [latest release](https://github.com/tobwil/pocketpane/releases/latest) and its SHA-256 checksum files.

### macOS

1. Download and extract the macOS ZIP.
2. Drag **PocketPane** into **Applications**.
3. Launch PocketPane and follow the wireless pairing guide.

The current build is ad-hoc signed but not yet Apple-notarized. If macOS blocks the first launch, open **System Settings → Privacy & Security** and choose **Open Anyway**.

### Windows

1. Download and extract the complete Windows ZIP.
2. Keep PocketPane.exe, PocketPane.Windows.ps1, and the bin folder together.
3. Double-click **PocketPane.exe**.

No separate ADB or scrcpy installation is needed. The executable is not yet code-signed, so Windows SmartScreen may display a warning.

## What PocketPane does

- **Cable-free mirroring and control** — pair Android 11+ with the standard Wireless debugging code, then reconnect over the local network.
- **Low-latency video and audio** — scrcpy provides the fast mirroring engine while PocketPane manages discovery, pairing, options, and recovery.
- **Android apps as desktop windows** — search installed apps and open one on its own scrcpy virtual display.
- **Files and captures** — drop files into PocketPane, save PNG screenshots, and record MP4 presentations.
- **Presentation controls** — show touches, keep the device awake, hide window borders, or turn the physical phone screen off.
- **Local and private** — no account, telemetry, advertisements, cloud relay, or phone companion app.

### macOS extras

- Native SwiftUI interface with a single Light/Dark Mode toggle
- Menu bar mode for nearby-device status and one-click actions
- Automatic clipboard synchronization while mirroring
- Keyboard-driven app launcher with ⌘K

### Windows app

- Portable PocketPane.exe launcher
- PowerShell/WPF desktop interface
- Wireless pairing, Wi-Fi connection, mirroring, screenshots, recordings, file drop, and app launching
- Reproducible Windows x64 packaging through GitHub Actions

## Android app launcher

Search the apps installed on the connected phone and launch one in a separate desktop window.

![PocketPane Android app launcher in Light Mode](https://github.com/user-attachments/assets/93230df0-6968-4fa9-b76d-b2a9750f8f10#gh-light-mode-only)
![PocketPane Android app launcher in Dark Mode](https://github.com/user-attachments/assets/90b860fe-ab6b-438d-abc4-45f3e93b3aee#gh-dark-mode-only)

## Real wireless mirroring

<p align="center">
  <img src="https://github.com/user-attachments/assets/486d71c5-3e6c-4d00-ac30-acfc4c16381c" alt="Pixel 10 Pro mirrored wirelessly in a PocketPane window" width="420">
</p>

## First connection

1. On Android, open **Settings → System → Developer options → Wireless debugging**.
2. Enable Wireless debugging and allow the current Wi-Fi network.
3. Tap **Pair device with pairing code** and keep that dialog open.
4. Enter the displayed pairing IP/port and six-digit code in PocketPane.
5. Close the pairing dialog on the phone after pairing succeeds.
6. PocketPane discovers the separate connection endpoint. If necessary, enter the IP/port shown on the main Wireless debugging screen.
7. Select the phone and start mirroring.

The temporary pairing port and the normal connection port are intentionally different. PocketPane keeps them separate and shows the active Wi-Fi endpoint with the connected device.

A one-time authorized USB connection remains available as an optional fallback for switching ADB to Wi-Fi.

## Requirements

### Android

- Android 11 or newer for cable-free pairing
- Developer options and **Wireless debugging** enabled
- Phone and computer on the same local network

PocketPane is developed with a Pixel 10 Pro. The underlying scrcpy engine supports Android API 21 and newer, while wireless pairing itself requires Android 11 or newer.

### macOS

- Apple Silicon Mac
- macOS 14 Sonoma or newer

### Windows

- x64 PC
- Windows 10 or newer
- Windows PowerShell 5.1 with WPF support (included with supported Windows versions)

## Build from source

### macOS

The native app has no third-party Swift package dependencies.

    git clone https://github.com/tobwil/pocketpane.git
    cd pocketpane
    chmod +x scripts/*.sh
    ./scripts/build-app.sh
    open dist/PocketPane.app

The build downloads the official scrcpy 4.0 archive for the current CPU architecture, verifies its published SHA-256 checksum, and embeds the required runtime files.

### Windows

Install the development tools and start the source version:

    Windows\Install-Tools-Windows.cmd
    Windows\Start-PocketPane-Windows.cmd

Build the portable Windows release and PocketPane.exe on Windows:

    .\Windows\Build-Windows-Release.ps1 -Version 0.2.0

The Windows build verifies the official scrcpy archive checksum and writes the ZIP plus its checksum to dist. The [Windows release workflow](.github/workflows/windows-release.yml) performs the same build on GitHub Actions.

More Windows details are in [Windows/README.md](Windows/README.md).

## Technology

| Layer | macOS | Windows | Purpose |
| --- | --- | --- | --- |
| Desktop UI | Swift 6, SwiftUI | PowerShell 5.1, WPF | Pairing, device selection, options, and launch flows |
| OS integration | AppKit, Foundation | .NET Framework, Windows dialogs | Menu bar, processes, files, save panels, and drag-and-drop |
| Mirroring | scrcpy 4.0 | scrcpy 4.0 | Video, audio, input control, recording, and virtual displays |
| Device transport | Android Debug Bridge | Android Debug Bridge | Secure pairing, TCP/IP connections, screenshots, and file transfer |
| Discovery | ADB mDNS / Bonjour | ADB mDNS | Finds wireless pairing and connection services |
| Packaging | Swift Package Manager, zsh | C# launcher, PowerShell, GitHub Actions | Self-contained platform downloads |

PocketPane launches scrcpy as a managed subprocess instead of reimplementing its codec, audio, and Android control stack.

## Repository layout

    Sources/PocketPane/             SwiftUI macOS application
    Sources/PocketPaneCore/         Swift ADB/scrcpy parsing and process utilities
    Sources/PocketPaneCoreChecks/   Executable core checks
    Windows/                        WPF app, EXE launcher, and Windows packager
    scripts/build-app.sh            macOS app-bundle packaging
    scripts/build-dmg.sh            macOS DMG and SHA-256 generation
    scripts/fetch-tools.sh          Verified macOS scrcpy download
    .github/workflows/              Automated Windows release packaging

## Privacy and security

- Screen, audio, clipboard, and file data travel locally between the desktop and Android device through ADB/scrcpy.
- PocketPane has no analytics SDK, user account, ad framework, cloud relay, or remote service.
- ADB stores its normal authentication keys in the current user profile.
- Android provides a **Forget** action for paired computers under Wireless debugging.
- Only pair on networks you trust.

## License

PocketPane source code is available under the [MIT License](LICENSE).

PocketPane bundles or downloads the official scrcpy 4.0 distributions. scrcpy is licensed under the [Apache License 2.0](https://github.com/Genymobile/scrcpy/blob/master/LICENSE). See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for included components and notices.

Android is a trademark of Google LLC. macOS is a trademark of Apple Inc. Windows is a trademark of Microsoft Corporation. PocketPane is an independent project and is not affiliated with Google, Apple, Microsoft, Genymobile, or the scrcpy maintainers.

## Website

[pocketpane.app](https://pocketpane.app)
