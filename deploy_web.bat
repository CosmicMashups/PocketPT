@echo off
REM Batch script to deploy web build to GitHub Pages using git subtree
REM This script builds the Flutter web app and deploys it using git subtree

echo Building Flutter web application...

REM Build the web application optimized for GitHub Pages
REM Try with pwa-strategy to avoid service worker caching; if unsupported, retry without it
flutter build web --release --base-href /pocketpt/ --pwa-strategy none
IF NOT %ERRORLEVEL%==0 (
    echo Retrying build without --pwa-strategy (not supported on this Flutter)
    flutter build web --release --base-href /pocketpt/
)

REM Ensure GitHub Pages does not use Jekyll and SPA routing works
IF EXIST build\web (
    type NUL > build\web\.nojekyll
    copy /Y build\web\index.html build\web\404.html > NUL

    REM Quick sanity check for critical files
    IF NOT EXIST build\web\index.html echo Missing index.html
    IF NOT EXIST build\web\main.dart.js echo Missing main.dart.js
    IF NOT EXIST build\web\flutter_bootstrap.js echo Missing flutter_bootstrap.js
)

if %ERRORLEVEL% EQU 0 (
    echo Web build completed successfully!
    echo Deploying to GitHub Pages using git subtree...
    
    REM Check if we're in a git repository
    if exist ".git" (
        echo Deploying using git subtree method...
        
        REM Execute the git subtree commands
        echo 1. Adding web build files to git...
        git add -f build/web/

        echo 2. Creating temporary deploy commit...
        git commit -m "chore(deploy): web build" --no-verify

        echo 3. Creating subtree branch...
        git subtree split --prefix build/web -b gh-pages-temp
        
        if %ERRORLEVEL% EQU 0 (
            echo 4. Pushing to gh-pages branch...
            git push origin gh-pages-temp:gh-pages --force
            
            if %ERRORLEVEL% EQU 0 (
                echo 5. Cleaning up temporary branch...
                git branch -D gh-pages-temp
                echo 6. Rewinding temporary deploy commit...
                git reset --soft HEAD~1
                git restore --staged build/web 2> NUL

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
