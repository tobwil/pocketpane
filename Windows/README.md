# PocketPane for Windows

PocketPane mirrors and controls Android phones over Wi-Fi. The Windows port uses PowerShell/WPF for its desktop interface, the official scrcpy for mirroring, and ADB for pairing, connections, screenshots, app listing, and file transfer.

## Download the portable release

Download [PocketPane-0.2.0-Windows-x64.zip](https://github.com/tobwil/pocketpane/releases/download/v0.2.0/PocketPane-0.2.0-Windows-x64.zip), extract the complete folder, and double-click **PocketPane.exe**.

ADB, scrcpy 4.0, and scrcpy-server are included in the release package. Users do not need to install them separately. Windows may show a SmartScreen warning because the executable is not yet code-signed.

## Requirements

- Windows 10 or newer, x64
- Android 11 or newer for Wireless debugging pairing
- Both devices on the same local network

Android 16 is supported. The Galaxy A53 5G is supported when it is running One UI 8 / Android 16 and Wireless debugging is enabled.

## Run from source

Install the official Windows tools by double-clicking:

    Windows\Install-Tools-Windows.cmd

Then launch:

    Windows\Start-PocketPane-Windows.cmd

Or run directly from PowerShell:

    powershell -ExecutionPolicy Bypass -File .\Windows\PocketPane.Windows.ps1

The source version searches for adb.exe and scrcpy.exe in Windows\bin, .tools, Android SDK paths, common install paths, and PATH.

## Current features

- Finds ADB devices and Wireless debugging mDNS services
- Pairs using the Android IP/port and 6 digit pairing code
- Connects over Wi-Fi, including the USB-to-Wi-Fi shortcut on port 5555
- Starts mirroring with resolution, FPS, audio, touch, screen-off, and borderless options
- Saves PNG screenshots and records MP4 presentations
- Sends dropped files to /sdcard/Download/
- Lists Android apps and launches them on a new scrcpy virtual display

## Building the executable release

On Windows, run:

    .\Windows\Build-Windows-Release.ps1 -Version 0.2.0

The build downloads the official scrcpy 4.0 archive, verifies its SHA-256 checksum, compiles PocketPane.exe, and creates a portable ZIP plus checksum in dist. The GitHub Actions workflow performs the same build and attaches both files to release v0.2.0.

## Samsung notes

On Samsung devices, enable Developer options first, then USB debugging and Wireless debugging. Windows may need the Samsung USB driver for USB setup. Windows Defender Firewall must allow ADB and scrcpy on the local network.
