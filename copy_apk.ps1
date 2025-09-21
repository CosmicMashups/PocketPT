# PowerShell script to copy APK files to Flutter's expected build directory
# This script should be run after each Flutter build to ensure APK files are in the correct location

$projectRoot = Split-Path -Parent $PSScriptRoot
$sourceDir = Join-Path $projectRoot "android\app\build\outputs\apk"
$targetDir = Join-Path $projectRoot "build\app\outputs\flutter-apk"

# Create target directory if it doesn't exist
if (!(Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force
    Write-Host "Created target directory: $targetDir"
}

# Copy all APK files from source to target
if (Test-Path $sourceDir) {
    $apkFiles = Get-ChildItem -Path $sourceDir -Recurse -Filter "*.apk"
    
    if ($apkFiles.Count -gt 0) {
        foreach ($apkFile in $apkFiles) {
            $targetFile = Join-Path $targetDir $apkFile.Name
            Copy-Item -Path $apkFile.FullName -Destination $targetFile -Force
            Write-Host "Copied: $($apkFile.Name) to $targetDir"
        }
        Write-Host "Successfully copied $($apkFiles.Count) APK file(s) to Flutter build directory"
    } else {
        Write-Host "No APK files found in $sourceDir"
    }
} else {
    Write-Host "Source directory not found: $sourceDir"
}









