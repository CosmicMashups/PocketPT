# PowerShell script to deploy Flutter web to GitHub Pages
# This script avoids the large file issue by copying only web build files

Write-Host "Building Flutter web app..."
flutter build web --release --base-href /PocketPT/

Write-Host "Creating clean deployment directory..."
if (Test-Path "deploy") {
    Remove-Item -Path "deploy" -Recurse -Force
}
New-Item -ItemType Directory -Path "deploy"

Write-Host "Copying web build files..."
Copy-Item -Path "build\web\*" -Destination "deploy" -Recurse

Write-Host "Deploying to GitHub Pages..."
cd deploy
git init
git add .
git commit -m "Deploy Flutter web app to GitHub Pages"
git branch -M gh-pages
git remote add origin https://github.com/CosmicMashups/PocketPT.git
git push -f origin gh-pages

Write-Host "Deployment complete!"
