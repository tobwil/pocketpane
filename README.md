# PocketPane

**Your Android, right here.**

PocketPane mirrors and controls Android devices from desktop computers using
[scrcpy](https://github.com/Genymobile/scrcpy) and Android Debug Bridge (ADB).
The project currently contains:

- a native macOS app built with SwiftUI
- a Windows preview app built with PowerShell/WPF

Both versions use local ADB/scrcpy connections. There is no cloud relay, account,
telemetry, advertising, or phone companion app.

[![macOS 14+](https://img.shields.io/badge/macOS-14%2B-111111?logo=apple)](https://www.apple.com/macos/)
[![Windows 10+](https://img.shields.io/badge/Windows-10%2B-0078D4?logo=windows)](Windows/README.md)
[![Swift 6](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)](https://www.swift.org/)
[![scrcpy 4.0](https://img.shields.io/badge/scrcpy-4.0-3DDC84?logo=android&logoColor=white)](https://github.com/Genymobile/scrcpy)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

![PocketPane in Dark Mode](assets/screenshots/pocketpane-dark.png)

## Highlights

- **Cable-free mirroring** - pair Android 11+ using the standard Wireless
  debugging code, then reconnect over the local network.
- **ADB and scrcpy powered** - PocketPane manages discovery, pairing, launch
  options, screenshots, file transfer, and recording while scrcpy handles the
  low-latency mirroring engine.
- **macOS native app** - SwiftUI dashboard, menu bar controls, screenshots,
  recordings, drag-and-drop file transfer, app launcher, and Light/Dark Mode.
- **Windows preview** - WPF desktop UI for pairing, Wi-Fi connect, mirroring,
  screenshots, MP4 recording, drag-and-drop file transfer, and Android app
  launching.
- **Android apps as desktop windows** - launch installed Android apps on a
  scrcpy virtual display.
- **Presentation controls** - record MP4 with device audio, show touches, use a
  borderless window, keep the device awake, or turn the physical phone screen
  off.
- **Local and private** - screen, audio, clipboard, and files stay on the local
  connection between your computer and Android device.

<p>
  <img src="assets/screenshots/pocketpane-light.png" alt="PocketPane in Light Mode" width="62%">
  <img src="assets/screenshots/pocketpane-app-launcher.png" alt="PocketPane Android app launcher" width="34%">
</p>

## Platform Status

| Platform | Status | Entry point |
| --- | --- | --- |
| macOS 14+ | Native app | `Sources/PocketPane`, `scripts/build-app.sh` |
| Windows 10+ | Preview app | `Windows/PocketPane.Windows.ps1` |

The macOS app is the original native application. The Windows app is a practical
preview implementation that runs without a separate build toolchain.

## Requirements

### Android

- Android 11 or newer for cable-free Wireless debugging pairing.
- Developer options and **Wireless debugging** enabled.
- Computer and Android device on the same local network.
- Android 16 is supported by the underlying ADB/scrcpy workflow.
- Samsung Galaxy A53 5G is supported when Wireless debugging is enabled. On
  Windows, USB setup may require the Samsung USB driver.

### macOS

- macOS 14 Sonoma or newer.
- Swift 6 toolchain for building from source.
- Release builds bundle the official scrcpy client, scrcpy server, and ADB
  executable.

### Windows

- Windows 10 or newer.
- Windows PowerShell 5.1 with WPF support.
- `adb.exe` and `scrcpy.exe`. The helper installer downloads the official
  scrcpy Windows archive, which includes both tools.

## First Connection

1. On Android, open **Settings -> System -> Developer options -> Wireless
   debugging**.
2. Enable Wireless debugging and allow the current Wi-Fi network.
3. Tap **Pair device with pairing code** and keep that pairing dialog open.
4. In PocketPane, enter the pairing IP/port and the six-digit code, then pair.
5. After pairing succeeds, close the pairing-code dialog on the phone.
6. Use the separate IP/port shown on the main Wireless debugging screen to
   connect, or press Refresh if PocketPane discovers it automatically.
7. Select the phone and start mirroring.

The pairing port and connection port are intentionally different. The temporary
pairing port is only for the six-digit code step. The main Wireless debugging
screen shows the connection port used after pairing.

For older workflows, connect and authorize the phone once over USB, then use
**Enable wireless via USB**.

## macOS Build

The macOS build has no third-party Swift package dependencies.

```sh
git clone https://github.com/tobwil/pocketpane.git
cd pocketpane
chmod +x scripts/*.sh
./scripts/build-app.sh
open dist/PocketPane.app
```

On first build, the script downloads the official scrcpy 4.0 macOS archive for
the current CPU architecture, verifies its published SHA-256 checksum, and
embeds the required runtime files. The resulting ad-hoc signed app is:

```text
dist/PocketPane.app
```

For public binary distribution, a release should additionally be signed with an
Apple Developer ID certificate and notarized.

## Windows Preview

Install ADB and scrcpy:

```text
Windows\Install-Tools-Windows.cmd
```

Start the Windows app:

```text
Windows\Start-PocketPane-Windows.cmd
```

Or run it directly:

```powershell
powershell -ExecutionPolicy Bypass -File .\Windows\PocketPane.Windows.ps1
```

More details are in [Windows/README.md](Windows/README.md).

## Technology

| Layer | macOS | Windows | Purpose |
| --- | --- | --- | --- |
| App and UI | Swift 6, SwiftUI | PowerShell 5.1, WPF | Desktop dashboard and controls |
| Desktop integration | AppKit | Windows dialogs and WPF events | Menus, save panels, drag-and-drop |
| System services | Foundation | .NET / PowerShell process APIs | Processes, files, persistence |
| Mirroring engine | scrcpy 4.0 | scrcpy 4.0 | Video, audio, input control, recording |
| Device transport | ADB | ADB | Pairing, TCP/IP connections, screenshots, file transfer |
| Discovery | ADB mDNS / Bonjour | ADB mDNS | Finds pairing and connection services |
| Packaging | Swift Package Manager, zsh | PowerShell scripts | Platform-specific distribution |

PocketPane launches scrcpy as a managed subprocess instead of reimplementing its
codec, audio, and Android control stack.

## Repository Layout

```text
Sources/PocketPane/            SwiftUI macOS application
Sources/PocketPaneCore/        Swift ADB/scrcpy parsing and process utilities
Sources/PocketPaneCoreChecks/  Fast executable core checks
Windows/                       Windows preview app and helper scripts
scripts/build-app.sh           macOS release build and app-bundle packaging
scripts/fetch-tools.sh         macOS scrcpy download and SHA-256 verification
scripts/render-screenshots.sh  Reproducible, privacy-safe README screenshots
assets/screenshots/            Generated product screenshots
```

## Privacy and Security

- Screen, audio, files, and clipboard data travel locally between the desktop
  computer and Android device through ADB/scrcpy.
- PocketPane has no analytics SDK, user account, ad framework, or remote
  service.
- ADB stores its normal authentication keys in the user's Android configuration
  directory, such as `~/.android` on macOS or the corresponding user profile
  location on Windows.
- Forgetting a pairing on the computer does not always remove the matching phone
  entry. Android also offers a **Forget** action under Wireless debugging.
- Only pair on networks you trust.

## Screenshots

The repository screenshots are rendered from PocketPane's real SwiftUI views
with a synthetic preview device, so they are reproducible and contain no
personal phone data:

```sh
./scripts/render-screenshots.sh
```

## License

PocketPane source code is available under the [MIT License](LICENSE).

PocketPane uses the official scrcpy distribution. scrcpy is licensed under the
[Apache License 2.0](https://github.com/Genymobile/scrcpy/blob/master/LICENSE).
See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for details.

Android is a trademark of Google LLC. macOS is a trademark of Apple Inc.
Windows is a trademark of Microsoft Corporation. PocketPane is an independent
project and is not affiliated with Google, Apple, Microsoft, Samsung,
Genymobile, or the scrcpy maintainers.
