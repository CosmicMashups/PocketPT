# PowerShell script to deploy web build to GitHub Pages using git subtree
# This script builds the Flutter web app and deploys it using git subtree

Write-Host "Building Flutter web application..." -ForegroundColor Green

# Build the web application in debug mode with correct base href for GitHub Pages
flutter build web --debug --base-href /pocketpt/

if ($LASTEXITCODE -eq 0) {
    Write-Host "Web build completed successfully!" -ForegroundColor Green
    Write-Host "Deploying to GitHub Pages using git subtree..." -ForegroundColor Yellow
    
    # Check if we're in a git repository
    if (Test-Path ".git") {
        Write-Host "Deploying using git subtree method..." -ForegroundColor Cyan
        
        # Execute the git subtree commands
        Write-Host "1. Adding web build files to git..." -ForegroundColor White
        git add -f build/web/
        
        Write-Host "2. Creating subtree branch..." -ForegroundColor White
        git subtree split --prefix build/web -b gh-pages-temp
        
            if ($LASTEXITCODE -eq 0) {
                Write-Host "3. Pushing to gh-pages branch..." -ForegroundColor White
                git push origin gh-pages-temp:gh-pages --force
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "4. Cleaning up temporary branch..." -ForegroundColor White
                    git branch -D gh-pages-temp
                
                Write-Host "Deployment completed successfully!" -ForegroundColor Green
                Write-Host "Your web app should be available at: https://yourusername.github.io/pocketpt" -ForegroundColor Cyan
            } else {
                Write-Host "Failed to push to gh-pages branch!" -ForegroundColor Red
            }
        } else {
            Write-Host "Failed to create subtree branch!" -ForegroundColor Red
        }
    } else {
        Write-Host "No git repository found. Please initialize git first." -ForegroundColor Red
    }
} else {
    Write-Host "Build failed! Please check the error messages above." -ForegroundColor Red
}
