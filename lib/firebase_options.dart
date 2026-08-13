import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Placeholder Firebase options.
///
/// Run `flutterfire configure` after creating your Firebase project. The
/// FlutterFire CLI will replace this file with real project values.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'Only Android is configured for the first version of this app.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAacTYrqM_CzbF8FqdjBHJzs2yW-4PP6qc',
    appId: '1:387609865539:android:cc0d1331e22a74a3a5d3f6',
    messagingSenderId: '387609865539',
    projectId: 'facility-report-test',
    storageBucket: 'facility-report-test.firebasestorage.app',
  );
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBXo9qO5Tr1cLGZ4Y3WbQ0zDjdPYdaddeI',
    appId: '1:387609865539:web:25d5eb0587b0eb01a5d3f6',
    messagingSenderId: '387609865539',
    projectId: 'facility-report-test',
    authDomain: 'facility-report-test.firebaseapp.com',
    storageBucket: 'facility-report-test.firebasestorage.app',
    measurementId: 'G-YE5XF0JR2C',
  );
}
