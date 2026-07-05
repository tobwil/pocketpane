Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$version = "4.0"
$scriptDir = Split-Path -Parent $PSCommandPath
$repoRoot = Split-Path -Parent $scriptDir
$toolsRoot = Join-Path $repoRoot ".tools"
$target = Join-Path $toolsRoot "scrcpy-win64-v$version"
$archive = Join-Path $toolsRoot "scrcpy-win64-v$version.zip"
$url = "https://github.com/Genymobile/scrcpy/releases/download/v$version/scrcpy-win64-v$version.zip"

if ((Test-Path (Join-Path $target "adb.exe")) -and (Test-Path (Join-Path $target "scrcpy.exe"))) {
    Write-Host "PocketPane Windows tools are already installed:"
    Write-Host $target
    exit 0
}

New-Item -ItemType Directory -Path $toolsRoot -Force | Out-Null

Write-Host "Downloading official scrcpy $version Windows tools..."
Write-Host $url
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $url -OutFile $archive

if (Test-Path $target) {
    Remove-Item -Path $target -Recurse -Force
}

Write-Host "Extracting tools..."
Expand-Archive -Path $archive -DestinationPath $toolsRoot -Force

if (-not (Test-Path (Join-Path $target "adb.exe")) -or -not (Test-Path (Join-Path $target "scrcpy.exe"))) {
    throw "The archive did not contain adb.exe and scrcpy.exe at the expected path."
}

Write-Host "Installed:"
Write-Host $target
Write-Host "Now start PocketPane again or press Refresh in the app."
