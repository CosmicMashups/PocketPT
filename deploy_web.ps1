# PowerShell script to deploy web build to GitHub Pages using git subtree
# This script builds the Flutter web app and deploys it using git subtree

Write-Host "Cleaning previous build..." -ForegroundColor Yellow
flutter clean

Write-Host "Restoring dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host "Building Flutter web application..." -ForegroundColor Green

# Build the web application optimized for GitHub Pages
# IMPORTANT: Use exact repository name casing for base-href
# Repository name: PocketPT (capital P and T)
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
  
  # Verify build timestamp (ensure it's a fresh build)
  $buildTime = (Get-Item "build/web/main.dart.js").LastWriteTime
  Write-Host "Build timestamp: $buildTime" -ForegroundColor Cyan
  $timeSinceBuild = (Get-Date) - $buildTime
  if ($timeSinceBuild.TotalMinutes -gt 5) {
    Write-Host "Warning: Build appears to be older than 5 minutes. Consider re-running the deployment." -ForegroundColor Yellow
  }
  
  # Verify CSV file is included and show its timestamp
  $sourceCsvPath = "assets/data/exercises.csv"
  $builtCsvPath = "build/web/assets/assets/data/exercises.csv"
  if (Test-Path $builtCsvPath) {
    $builtCsvTime = (Get-Item $builtCsvPath).LastWriteTime
    $builtCsvSize = (Get-Item $builtCsvPath).Length
    Write-Host "CSV file found in build: $builtCsvPath (Size: $builtCsvSize bytes, Modified: $builtCsvTime)" -ForegroundColor Green
    
    # Compare with source CSV if it exists
    if (Test-Path $sourceCsvPath) {
      $sourceCsvTime = (Get-Item $sourceCsvPath).LastWriteTime
      $sourceCsvSize = (Get-Item $sourceCsvPath).Length
      Write-Host "Source CSV: $sourceCsvPath (Size: $sourceCsvSize bytes, Modified: $sourceCsvTime)" -ForegroundColor Cyan
      
      if ($sourceCsvTime -gt $builtCsvTime) {
        Write-Host "Warning: Source CSV is newer than built CSV. Build may be using cached version." -ForegroundColor Yellow
        Write-Host "Consider running 'flutter clean' before building." -ForegroundColor Yellow
      }
    }
  } else {
    Write-Host "Warning: CSV file not found in build: $builtCsvPath" -ForegroundColor Yellow
  }
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
        Write-Host "Adding web build files to git..." -ForegroundColor White
        git add -f build/web/
        
        # Create temporary deploy commit
        Write-Host "Creating temporary deploy commit..." -ForegroundColor White
        git commit -m "chore(deploy): web build $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" --allow-empty --no-verify

        # Split subtree and push to gh-pages
        Write-Host "Splitting subtree to gh-pages-temp branch..." -ForegroundColor White
        git subtree split --prefix build/web -b gh-pages-temp
        if ($LASTEXITCODE -ne 0) { throw "Failed to create subtree branch" }

        # Verify subtree branch has files at root
        Write-Host "Verifying subtree branch contents..." -ForegroundColor White
        $subtreeFiles = git ls-tree -r --name-only gh-pages-temp
        if ($subtreeFiles -notcontains "index.html") { 
            throw "index.html missing in subtree branch" 
        }
        if ($subtreeFiles -notcontains "flutter_bootstrap.js") { 
            throw "flutter_bootstrap.js missing in subtree branch" 
        }
        if ($subtreeFiles -notcontains "manifest.json") { 
            Write-Host "Warning: manifest.json missing in subtree branch" -ForegroundColor Yellow
        }
        if ($subtreeFiles -notcontains ".nojekyll") { 
            Write-Host "Warning: .nojekyll missing in subtree branch" -ForegroundColor Yellow
        }
        if ($subtreeFiles -notcontains "assets/assets/data/exercises.csv") { 
            Write-Host "Warning: exercises.csv missing in subtree branch" -ForegroundColor Yellow
        } else {
            Write-Host "Verified: exercises.csv included in subtree branch" -ForegroundColor Green
        }
        Write-Host "Found $($subtreeFiles.Count) files in subtree branch" -ForegroundColor Green

        Write-Host "Pushing to gh-pages branch..." -ForegroundColor White
        git push origin gh-pages-temp:gh-pages --force
        if ($LASTEXITCODE -ne 0) { throw "Failed to push to gh-pages" }

        # Cleanup
        git branch -D gh-pages-temp
        git reset --soft HEAD~1
        git restore --staged build/web 2>$null

        Write-Host "Deployment completed successfully!" -ForegroundColor Green
        Write-Host "Your web app should be available at: https://cosmicmashups.github.io/PocketPT/" -ForegroundColor Cyan
        Write-Host "Note: GitHub Pages may take 1-2 minutes to update. Hard refresh (Ctrl+F5) if files don't load." -ForegroundColor Yellow
        Write-Host "If CSV data appears outdated, clear browser cache for the site or use Incognito mode." -ForegroundColor Yellow
    } else {
        Write-Host "No git repository found. Please initialize git first." -ForegroundColor Red
    }
} else {
    Write-Host "Build failed! Please check the error messages above." -ForegroundColor Red
}
