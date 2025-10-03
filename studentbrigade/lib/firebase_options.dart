import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // TEMPORAL - después lo cambiaremos con tus datos reales
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'TEMP_KEY',
    appId: 'TEMP_APP_ID',
    messagingSenderId: 'TEMP_SENDER',
    projectId: 'TEMP_PROJECT',
    storageBucket: 'TEMP_PROJECT.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'TEMP_KEY',
    appId: 'TEMP_APP_ID',
    messagingSenderId: 'TEMP_SENDER',
    projectId: 'TEMP_PROJECT',
    storageBucket: 'TEMP_PROJECT.appspot.com',
    iosBundleId: 'com.example.studentbrigade',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'TEMP_KEY',
    appId: 'TEMP_APP_ID',
    messagingSenderId: 'TEMP_SENDER',
    projectId: 'TEMP_PROJECT',
    authDomain: 'TEMP_PROJECT.firebaseapp.com',
    storageBucket: 'TEMP_PROJECT.appspot.com',
  );
}