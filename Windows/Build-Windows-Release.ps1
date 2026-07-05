param(
    [string]$Version = "0.2.0"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$scrcpyVersion = "4.0"
$scrcpyArchiveName = "scrcpy-win64-v$scrcpyVersion.zip"
$scrcpyUrl = "https://github.com/Genymobile/scrcpy/releases/download/v$scrcpyVersion/$scrcpyArchiveName"
$scrcpySha256 = "75dbeb5b00e6f64292f26f70900ae55ca397786bdfb0b9bbeb481a0549047457"

$repoRoot = Split-Path -Parent $PSScriptRoot
$distRoot = Join-Path $repoRoot "dist"
$workRoot = Join-Path ([IO.Path]::GetTempPath()) ("PocketPane-Windows-" + [Guid]::NewGuid().ToString("N"))
$downloadPath = Join-Path $workRoot $scrcpyArchiveName
$extractRoot = Join-Path $workRoot "scrcpy"
$packageName = "PocketPane-$Version-Windows-x64"
$packageRoot = Join-Path $distRoot $packageName
$zipPath = Join-Path $distRoot "$packageName.zip"
$checksumPath = "$zipPath.sha256"

try {
    New-Item -ItemType Directory -Path $workRoot, $extractRoot, $distRoot -Force | Out-Null
    Remove-Item $packageRoot, $zipPath, $checksumPath -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host "Downloading official scrcpy $scrcpyVersion for Windows..."
    Invoke-WebRequest -Uri $scrcpyUrl -OutFile $downloadPath -UseBasicParsing

    $actualHash = (Get-FileHash -Path $downloadPath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualHash -ne $scrcpySha256) {
        throw "scrcpy checksum mismatch. Expected $scrcpySha256 but received $actualHash."
    }

    Expand-Archive -Path $downloadPath -DestinationPath $extractRoot -Force
    $scrcpyRoot = Get-ChildItem -Path $extractRoot -Directory |
        Where-Object { Test-Path (Join-Path $_.FullName "scrcpy.exe") } |
        Select-Object -First 1
    if (-not $scrcpyRoot) {
        throw "scrcpy.exe was not found in the downloaded archive."
    }

    New-Item -ItemType Directory -Path $packageRoot, (Join-Path $packageRoot "bin") -Force | Out-Null
    Copy-Item -Path (Join-Path $PSScriptRoot "PocketPane.Windows.ps1") -Destination $packageRoot
    Copy-Item -Path (Join-Path $scrcpyRoot.FullName "*") -Destination (Join-Path $packageRoot "bin") -Recurse -Force

    foreach ($file in @("LICENSE", "THIRD_PARTY_NOTICES.md")) {
        $source = Join-Path $repoRoot $file
        if (Test-Path $source) { Copy-Item $source $packageRoot }
    }
    $windowsReadme = Join-Path $PSScriptRoot "README.md"
    if (Test-Path $windowsReadme) {
        Copy-Item $windowsReadme (Join-Path $packageRoot "README-Windows.md")
    }

    $compilerCandidates = @(
        (Join-Path $env:WINDIR "Microsoft.NET\Framework64\v4.0.30319\csc.exe"),
        (Join-Path $env:WINDIR "Microsoft.NET\Framework\v4.0.30319\csc.exe")
    )
    $compiler = $compilerCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $compiler) { throw "The Windows C# compiler (csc.exe) was not found." }

    $launcherSource = Join-Path $PSScriptRoot "PocketPane.Launcher.cs"
    $launcherExe = Join-Path $packageRoot "PocketPane.exe"
    & $compiler /nologo /target:winexe /optimize+ "/out:$launcherExe" $launcherSource
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $launcherExe)) {
        throw "PocketPane.exe could not be compiled."
    }

    Compress-Archive -Path $packageRoot -DestinationPath $zipPath -CompressionLevel Optimal
    $zipHash = (Get-FileHash -Path $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
    "$zipHash  $([IO.Path]::GetFileName($zipPath))" | Set-Content -Path $checksumPath -Encoding ASCII

    Write-Host "Created $zipPath"
    Write-Host "Created $checksumPath"
}
finally {
    Remove-Item $workRoot -Recurse -Force -ErrorAction SilentlyContinue
}
