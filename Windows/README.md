# PocketPane for Windows

This folder contains a Windows implementation of PocketPane as a PowerShell/WPF
desktop app. It mirrors and controls Android devices by launching the official
`scrcpy.exe` and uses `adb.exe` for pairing, connection management,
screenshots, app listing, and file transfer.

## Requirements

- Windows 10 or newer.
- PowerShell 5.1 with WPF support.
- Android Platform Tools (`adb.exe`).
- scrcpy for Windows (`scrcpy.exe`).
- Android 11 or newer for Wireless debugging pairing.

Android 16 is supported because scrcpy supports Android API 21+ and ADB Wireless
debugging pairing is available on Android 11+. The Galaxy A53 5G is supported
when it is running One UI 8 / Android 16 and Wireless debugging is enabled.

## Install ADB and scrcpy

Double-click:

```text
Windows\Install-Tools-Windows.cmd
```

This downloads the official `scrcpy-win64-v4.0.zip` release from GitHub into
`.tools\scrcpy-win64-v4.0`. The archive includes both `scrcpy.exe` and
`adb.exe`.

## Run

From this repository:

```powershell
powershell -ExecutionPolicy Bypass -File .\Windows\PocketPane.Windows.ps1
```

You can also double-click:

```text
Windows\Start-PocketPane-Windows.cmd
```

The app searches for `adb.exe` and `scrcpy.exe` in:

- `Windows\bin`
- `.tools`
- Android SDK environment paths
- common Android SDK and scrcpy install paths
- `PATH`

## Current features

- Finds ADB devices and Wireless debugging mDNS services.
- Pairs with Android Wireless debugging by IP/port and 6 digit code.
- Connects over Wi-Fi, including the USB-to-Wi-Fi shortcut on port 5555.
- Starts scrcpy mirroring with resolution, FPS, audio, touch, screen-off, and
  borderless options.
- Saves PNG screenshots.
- Records MP4 presentations through scrcpy.
- Sends dropped files to `/sdcard/Download/`.
- Lists launchable Android apps and starts a selected app on a new scrcpy
  virtual display.

## Samsung A53 notes

On Samsung devices, enable Developer options first, then enable USB debugging
and Wireless debugging. For USB setup, Windows may need the Samsung USB driver.
For wireless setup, Windows Defender Firewall must allow ADB/scrcpy on the
local network.
