# PocketPT Web Deployment Guide

This guide explains how to deploy the PocketPT Flutter web application to GitHub Pages using git subtree.

## Prerequisites

- Flutter SDK installed and configured
- Git repository with GitHub remote
- GitHub Pages enabled for your repository

## Deployment Methods

### Method 1: Automated Script Deployment (Recommended)

Use the provided deployment scripts that automate the git subtree process:

#### Using PowerShell (Windows)
```powershell
.\deploy_web.ps1
```

#### Using Batch Script (Windows)
```cmd
deploy_web.bat
```

### Method 2: Manual Deployment

Execute the following commands manually:

1. Build the web application:
   ```bash
   flutter build web --debug
   ```

2. Deploy using git subtree:
   ```bash
   git subtree split --prefix build/web -b gh-pages-temp
   git push origin gh-pages-temp:gh-pages --force
   git branch -D gh-pages-temp
   ```

### Method 3: GitHub Pages Setup

1. Enable GitHub Pages in your repository settings:
   - Go to Settings → Pages
   - Select "Deploy from a branch"
   - Choose "gh-pages" branch as the source
   - Save the settings

2. Your web app will be available at:
   `https://yourusername.github.io/pocketpt`

## Configuration

### GitHub Pages Settings
- Source: Deploy from a branch
- Branch: gh-pages

### Build Configuration
The web build is configured in `pubspec.yaml` and includes:
- Custom fonts (Poppins, PT Sans)
- Assets (images, videos, data files)
- Firebase integration
- ML Kit pose detection
- Debug mode build for faster development

### File Structure
```
build/web/
├── index.html          # Main entry point
├── main.dart.js        # Compiled Dart code
├── assets/             # Application assets
├── canvaskit/          # Flutter web engine
└── icons/              # PWA icons
```

## Troubleshooting

### Build Issues
- Ensure all dependencies are installed: `flutter pub get`
- Check for any compilation errors in the console
- Verify that all assets are properly referenced

### Deployment Issues
- Check GitHub Actions logs for build errors
- Ensure GitHub Pages is enabled in repository settings
- Verify the workflow file is in the correct location (`.github/workflows/`)

### Web App Issues
- Check browser console for JavaScript errors
- Verify that all assets are loading correctly
- Test on different browsers and devices

## Custom Domain (Optional)

To use a custom domain:
1. Add a `CNAME` file to the `build/web` directory with your domain
2. Configure DNS settings to point to GitHub Pages
3. Enable HTTPS in GitHub Pages settings

## Performance Optimization

The web build includes several optimizations:
- Release mode compilation
- Asset compression
- Service worker for caching
- Progressive Web App features

## Security Considerations

- Firebase configuration is included in the build
- Ensure sensitive data is not exposed in client-side code
- Use environment variables for API keys when possible
- Regularly update dependencies for security patches
