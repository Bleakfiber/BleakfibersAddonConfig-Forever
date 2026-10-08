<#
    Bleakfiber's Addon Config - Forever
    Automated Packaging Script
    Usage:
        .\package.ps1
        .\package.ps1 -Version "1.0.10" -Notes "Description of changes"
#>

param (
    [string]$Version,
    [string]$Notes
)

$ErrorActionPreference = "Stop"
$rootDir = $PSScriptRoot
$addonDir = Join-Path $rootDir "BleakfibersAddonConfig-Forever"
$tocFile = Join-Path $addonDir "BleakfibersAddonConfig-Forever.toc"
$coreFile = Join-Path $addonDir "Core.lua"
$changelogFile = Join-Path $rootDir "changelog.md"

if (-not (Test-Path $tocFile)) {
    Write-Error "Could not locate $tocFile"
    exit 1
}

# If Version provided, update TOC and Core.lua
if ($Version) {
    Write-Host "Updating version to $Version..." -ForegroundColor Cyan
    (Get-Content $tocFile) -replace '^## Version: .*$', "## Version: $Version" | Set-Content $tocFile
    (Get-Content $coreFile) -replace 'BAC\.version = ".*"', "BAC.version = `"$Version`"" | Set-Content $coreFile
} else {
    # Extract current version from TOC
    $tocContent = Get-Content $tocFile -Raw
    if ($tocContent -match '## Version:\s*([^\r\n]+)') {
        $Version = $matches[1].Trim()
    } else {
        $Version = "1.0.10"
    }
}

Write-Host "Building release for version: $Version" -ForegroundColor Green

# Update or check changelog entry
if (Test-Path $changelogFile) {
    $changelog = Get-Content $changelogFile -Raw
    if ($changelog -notmatch "\[$Version\]") {
        $dateStr = (Get-Date).ToString("yyyy-MM-dd")
        $noteBody = if ($Notes) { "- $Notes" } else { "- Maintenance and bug fix update." }
        $entry = @"

## [$Version] - $dateStr

### Changed
$noteBody

"@
        # Insert after "# Changelog\n\nAll notable changes..." header
        if ($changelog -match "(# Changelog[\s\S]*?\n\n)") {
            $header = $matches[1]
            $changelog = $changelog.Replace($header, $header + $entry.TrimStart() + "`n")
        } else {
            $changelog = $entry + "`n" + $changelog
        }
        Set-Content -Path $changelogFile -Value $changelog -NoNewline
        Write-Host "Added entry to changelog.md for [$Version]" -ForegroundColor Yellow
    }
}

# Ensure \zips directory exists
$zipsDir = Join-Path $rootDir "zips"
if (-not (Test-Path $zipsDir)) {
    New-Item -ItemType Directory -Path $zipsDir -Force | Out-Null
}

# Create Zip Archive directly in \zips
$zipName = "BleakfibersAddonConfig-Forever $Version.zip"
$zipPath = Join-Path $zipsDir $zipName

Write-Host "Compressing addon into zips/$zipName..." -ForegroundColor Cyan
Compress-Archive -Path $addonDir -DestinationPath $zipPath -Force

# Clean up duplicate / legacy zip archives in root
Get-ChildItem -Path $rootDir -Filter "*.zip" -File | ForEach-Object {
    $targetInZips = Join-Path $zipsDir $_.Name
    if (-not (Test-Path $targetInZips)) {
        Move-Item -Path $_.FullName -Destination $targetInZips -Force
        Write-Host "Moved legacy archive to zips/$($_.Name)" -ForegroundColor Cyan
    } else {
        Remove-Item -Path $_.FullName -Force
        Write-Host "Removed duplicate root archive: $($_.Name)" -ForegroundColor Yellow
    }
}

$changelogsDir = Join-Path $rootDir "changelogs"
if (Test-Path $changelogsDir) {
    Copy-Item -Path $changelogFile -Destination (Join-Path $changelogsDir "changelog.md") -Force
}

Write-Host "Successfully packaged: zips/$zipName" -ForegroundColor Green
