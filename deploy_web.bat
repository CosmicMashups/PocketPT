@echo off
REM Batch script to deploy web build to GitHub Pages using git subtree
REM This script builds the Flutter web app and deploys it using git subtree

echo Building Flutter web application...

REM Build the web application in debug mode with correct base href for GitHub Pages
flutter build web --debug --base-href /pocketpt/

if %ERRORLEVEL% EQU 0 (
    echo Web build completed successfully!
    echo Deploying to GitHub Pages using git subtree...
    
    REM Check if we're in a git repository
    if exist ".git" (
        echo Deploying using git subtree method...
        
        REM Execute the git subtree commands
        echo 1. Adding web build files to git...
        git add -f build/web/
        
        echo 2. Creating subtree branch...
        git subtree split --prefix build/web -b gh-pages-temp
        
        if %ERRORLEVEL% EQU 0 (
            echo 3. Pushing to gh-pages branch...
            git push origin gh-pages-temp:gh-pages --force
            
            if %ERRORLEVEL% EQU 0 (
                echo 4. Cleaning up temporary branch...
                git branch -D gh-pages-temp
                
                echo Deployment completed successfully!
                echo Your web app should be available at: https://yourusername.github.io/pocketpt
            ) else (
                echo Failed to push to gh-pages branch!
            )
        ) else (
            echo Failed to create subtree branch!
        )
    ) else (
        echo No git repository found. Please initialize git first.
    )
) else (
    echo Build failed! Please check the error messages above.
)

pause
