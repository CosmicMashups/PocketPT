# PowerShell script to deploy web build to GitHub Pages using git subtree
# This script builds the Flutter web app and deploys it using git subtree

Write-Host "Building Flutter web application..." -ForegroundColor Green

# Build the web application optimized for GitHub Pages
# IMPORTANT: Use the exact repository name casing in base-href
# Attempt with pwa-strategy to avoid service worker caching; if unsupported, retry without it
flutter build web --debug --base-href /PocketPT/ --pwa-strategy none
if ($LASTEXITCODE -ne 0) {
  Write-Host "Retrying build without --pwa-strategy (not supported on this Flutter)" -ForegroundColor Yellow
  flutter build web --debug --base-href /PocketPT/
}

# Ensure GitHub Pages does not use Jekyll and SPA routing works
if (Test-Path "build/web") {
  New-Item -ItemType File -Path "build/web/.nojekyll" -Force | Out-Null
  Copy-Item -Path "build/web/index.html" -Destination "build/web/404.html" -Force

  # Quick sanity check for critical files
  if (-not (Test-Path "build/web/index.html")) { Write-Host "Missing index.html" -ForegroundColor Red }
  if (-not (Test-Path "build/web/main.dart.js")) { Write-Host "Missing main.dart.js" -ForegroundColor Red }
  if (-not (Test-Path "build/web/flutter_bootstrap.js")) { Write-Host "Missing flutter_bootstrap.js" -ForegroundColor Red }
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "Web build completed successfully!" -ForegroundColor Green
    Write-Host "Deploying to GitHub Pages using git subtree..." -ForegroundColor Yellow
    
    # Check if we're in a git repository
    if (Test-Path ".git") {
        Write-Host "Deploying using git subtree split..." -ForegroundColor Cyan

        # Sanity checks for critical files
        if (-not (Test-Path "build/web/index.html")) { throw "Missing build/web/index.html" }
        if (-not (Test-Path "build/web/flutter_bootstrap.js")) { throw "Missing build/web/flutter_bootstrap.js" }

        # Force add web build (in case parent build is ignored)
        git add -f build/web/

        # Create temporary deploy commit
        git commit -m "chore(deploy): web build" --allow-empty --no-verify

        # Split subtree and push to gh-pages
        git subtree split --prefix build/web -b gh-pages-temp
        if ($LASTEXITCODE -ne 0) { throw "Failed to create subtree branch" }

        git push origin gh-pages-temp:gh-pages --force
        if ($LASTEXITCODE -ne 0) { throw "Failed to push to gh-pages" }

        # Cleanup
        git branch -D gh-pages-temp
        git reset --soft HEAD~1
        git restore --staged build/web 2>$null

        Write-Host "Deployment completed successfully!" -ForegroundColor Green
        Write-Host "Your web app should be available at: https://yourusername.github.io/pocketpt" -ForegroundColor Cyan
    } else {
        Write-Host "No git repository found. Please initialize git first." -ForegroundColor Red
    }
} else {
    Write-Host "Build failed! Please check the error messages above." -ForegroundColor Red
}
