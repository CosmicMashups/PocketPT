// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBsf2ohYBu2iTdfg6Ey5FzLH0j4qP1ifpw',
    appId: '1:679886971863:web:73044012675bfe61e9a192',
    messagingSenderId: '679886971863',
    projectId: 'pocketpt-3d5f7',
    authDomain: 'pocketpt-3d5f7.firebaseapp.com',
    storageBucket: 'pocketpt-3d5f7.firebasestorage.app',
    measurementId: 'G-CRRKCQJNXF',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDxgw6ANOak_AxdckYUZ_oYdS_3K6LAgnw',
    appId: '1:679886971863:android:d99bc3ea2d3bc122e9a192',
    messagingSenderId: '679886971863',
    projectId: 'pocketpt-3d5f7',
    storageBucket: 'pocketpt-3d5f7.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCEd-7ypHGnELBMMAEpUQ-z6ZaH_08tqSk',
    appId: '1:679886971863:ios:c7cea59d1f91c688e9a192',
    messagingSenderId: '679886971863',
    projectId: 'pocketpt-3d5f7',
    storageBucket: 'pocketpt-3d5f7.firebasestorage.app',
    iosBundleId: 'com.example.pocketpt',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCEd-7ypHGnELBMMAEpUQ-z6ZaH_08tqSk',
    appId: '1:679886971863:ios:c7cea59d1f91c688e9a192',
    messagingSenderId: '679886971863',
    projectId: 'pocketpt-3d5f7',
    storageBucket: 'pocketpt-3d5f7.firebasestorage.app',
    iosBundleId: 'com.example.pocketpt',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBsf2ohYBu2iTdfg6Ey5FzLH0j4qP1ifpw',
    appId: '1:679886971863:web:4ae92028cd589db3e9a192',
    messagingSenderId: '679886971863',
    projectId: 'pocketpt-3d5f7',
    authDomain: 'pocketpt-3d5f7.firebaseapp.com',
    storageBucket: 'pocketpt-3d5f7.firebasestorage.app',
    measurementId: 'G-CQLT34RGDG',
  );
}
