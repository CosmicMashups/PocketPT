# PocketPT Web Deployment Troubleshooting Guide

## Common Issues and Solutions

### 1. Base Href Issues ✅ FIXED
**Problem**: Web app loads but assets don't load properly on GitHub Pages
**Solution**: Use correct base href for GitHub Pages deployment
```bash
flutter build web --debug --base-href /pocketpt/
```

### 2. Firebase Configuration Issues
**Problem**: Firebase authentication or Firestore not working on web
**Symptoms**: 
- Login fails
- Data sync errors
- Console errors about Firebase

**Solutions**:
- Verify Firebase web configuration in `firebase_options.dart`
- Check that `authDomain` is correctly set to `pocketpt-3d5f7.firebaseapp.com`
- Ensure Firebase project has web app enabled
- Check browser console for CORS errors

### 3. Asset Loading Issues
**Problem**: Images, fonts, or other assets not loading
**Symptoms**:
- Missing images
- Default fonts instead of custom fonts
- 404 errors in browser console

**Solutions**:
- Verify all assets are included in `pubspec.yaml`
- Check that asset paths are correct in the build
- Ensure assets are copied to `build/web/assets/`

### 4. Service Worker Issues
**Problem**: App doesn't work offline or has caching issues
**Symptoms**:
- App doesn't load after first visit
- Stale content
- Service worker errors in console

**Solutions**:
- Check `flutter_service_worker.js` is present
- Verify service worker registration in `index.html`
- Clear browser cache and test

### 5. CORS and Security Issues
**Problem**: API calls fail due to CORS policy
**Symptoms**:
- Network errors in console
- Firebase requests failing
- Authentication not working

**Solutions**:
- Verify Firebase domain configuration
- Check that all external domains are whitelisted
- Ensure HTTPS is used (GitHub Pages provides this)

### 6. JavaScript Bundle Issues
**Problem**: Main app doesn't load
**Symptoms**:
- Blank page
- JavaScript errors in console
- `main.dart.js` not loading

**Solutions**:
- Check that `main.dart.js` is present and not corrupted
- Verify Flutter web compilation completed successfully
- Test with a simple Flutter web app first

## Debugging Steps

### 1. Check Browser Console
Open browser developer tools (F12) and check for:
- JavaScript errors
- Network request failures
- Console warnings

### 2. Verify Build Output
```bash
# Check build directory contents
ls -la build/web/

# Verify key files exist
ls build/web/index.html
ls build/web/main.dart.js
ls build/web/flutter_bootstrap.js
```

### 3. Test Locally
```bash
# Serve the web build locally
cd build/web
python -m http.server 8000
# or
npx serve build/web
```

### 4. Check GitHub Pages Settings
- Repository Settings → Pages
- Source: Deploy from a branch
- Branch: gh-pages
- Custom domain: (if applicable)

## Firebase-Specific Issues

### Authentication Problems
- Check Firebase Console → Authentication → Settings
- Verify authorized domains include your GitHub Pages domain
- Test with Firebase Auth emulator locally

### Firestore Issues
- Check Firebase Console → Firestore → Rules
- Verify read/write permissions
- Test with Firebase emulator locally

### Storage Issues
- Check Firebase Console → Storage → Rules
- Verify file upload permissions
- Test with Firebase emulator locally

## Performance Issues

### Large Bundle Size
- Use `flutter build web --release` for production
- Enable tree shaking: `flutter build web --tree-shake-icons`
- Check bundle analyzer for large dependencies

### Slow Loading
- Enable compression on GitHub Pages
- Optimize images and assets
- Use CDN for static assets

## Testing Checklist

- [ ] App loads without JavaScript errors
- [ ] Firebase authentication works
- [ ] Data syncs properly
- [ ] All images and assets load
- [ ] Navigation works correctly
- [ ] Forms submit properly
- [ ] Works on mobile browsers
- [ ] Works on desktop browsers
- [ ] Works offline (if PWA features used)

## Emergency Rollback

If deployment fails:
1. Revert to previous working commit
2. Check git history for working deployment
3. Use `git subtree split` with previous commit
4. Force push to gh-pages branch

## Contact Support

If issues persist:
1. Check Firebase Console for errors
2. Review GitHub Pages deployment logs
3. Test with minimal Flutter web app
4. Check Flutter web documentation for updates
