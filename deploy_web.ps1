# PowerShell script to deploy web build to GitHub Pages using git subtree
# This script builds the Flutter web app and deploys it using git subtree

Write-Host "Building Flutter web application..." -ForegroundColor Green

# Build the web application optimized for GitHub Pages
# Attempt with pwa-strategy to avoid service worker caching; if unsupported, retry without it
flutter build web --debug --base-href /pocketpt/ --pwa-strategy none
if ($LASTEXITCODE -ne 0) {
  Write-Host "Retrying build without --pwa-strategy (not supported on this Flutter)" -ForegroundColor Yellow
  flutter build web --debug --base-href /pocketpt/
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
        Write-Host "Deploying using gh-pages worktree..." -ForegroundColor Cyan

        # Sanity checks for critical files
        if (-not (Test-Path "build/web/index.html")) { throw "Missing build/web/index.html" }
        if (-not (Test-Path "build/web/flutter_bootstrap.js")) { throw "Missing build/web/flutter_bootstrap.js" }
        if (-not (Test-Path "build/web/manifest.json")) { Write-Host "Warning: manifest.json missing" -ForegroundColor Yellow }

        # Ensure gh-pages branch exists locally (tracking remote if present)
        git show-ref --verify --quiet refs/heads/gh-pages
        if ($LASTEXITCODE -ne 0) {
          git fetch origin gh-pages 2>$null
          if ($LASTEXITCODE -eq 0) {
            git branch gh-pages origin/gh-pages
          } else {
            git branch gh-pages
          }
        }

        # Prepare worktree directory (handle stale registrations)
        $deployDir = ".gh-pages"
        git worktree prune 2>$null
        if (Test-Path $deployDir) {
          git worktree remove $deployDir --force 2>$null
          Remove-Item -Recurse -Force $deployDir -ErrorAction SilentlyContinue
        }
        git worktree add -f $deployDir gh-pages
        if ($LASTEXITCODE -ne 0) { throw "Failed to create gh-pages worktree" }

        # Clean worktree contents
        Get-ChildItem -Path $deployDir -Force | Where-Object { $_.Name -ne ".git" } | Remove-Item -Recurse -Force

        # Copy build output (use robocopy for reliability on Windows, includes all files)
        $src = (Resolve-Path "build/web").Path
        $dst = (Resolve-Path $deployDir).Path
        robocopy "$src" "$dst" /MIR /NFL /NDL /NJH /NJS /NP | Out-Null

        # Verify critical files exist after copy
        if (-not (Test-Path "$deployDir/index.html")) { throw "index.html missing in gh-pages" }
        if (-not (Test-Path "$deployDir/flutter_bootstrap.js")) { throw "flutter_bootstrap.js missing in gh-pages" }
        if (-not (Test-Path "$deployDir/manifest.json")) { Write-Host "Warning: manifest.json missing in gh-pages" -ForegroundColor Yellow }
        if (-not (Test-Path "$deployDir/splash/img/light-background.png")) { Write-Host "Warning: splash images missing in gh-pages" -ForegroundColor Yellow }

        Push-Location $deployDir
        git add --all
        git commit -m "deploy: update web build" --allow-empty --no-verify
        git push origin gh-pages --force
        Pop-Location

        # Detach worktree
        git worktree remove $deployDir --force

        Write-Host "Deployment completed successfully!" -ForegroundColor Green
        Write-Host "Your web app should be available at: https://yourusername.github.io/pocketpt" -ForegroundColor Cyan
    } else {
        Write-Host "No git repository found. Please initialize git first." -ForegroundColor Red
    }
} else {
    Write-Host "Build failed! Please check the error messages above." -ForegroundColor Red
}
