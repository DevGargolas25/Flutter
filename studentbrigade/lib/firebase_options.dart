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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCtJdobt0lrgxoEZXWGosRfkPfNZDOS7VM',
    appId: '1:993666193997:android:5eeccd257eb81ebdf89a04',
    messagingSenderId: '993666193997',
    projectId: 'brigadist-29309',
    databaseURL: 'https://brigadist-29309-default-rtdb.firebaseio.com',
    storageBucket: 'brigadist-29309.firebasestorage.app',
  );

  // TEMPORAL - después lo cambiaremos con tus datos reales

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'TEMP_KEY',
    appId: 'TEMP_APP_ID',
    messagingSenderId: 'TEMP_SENDER',
    projectId: 'TEMP_PROJECT',
    storageBucket: 'TEMP_PROJECT.appspot.com',
    iosBundleId: 'com.example.studentbrigade',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAQs2XnKNPhKRzDD6-ZlIU_OCESILQYjf0',
    appId: '1:993666193997:web:c12a2383cb871810f89a04',
    messagingSenderId: '993666193997',
    projectId: 'brigadist-29309',
    authDomain: 'brigadist-29309.firebaseapp.com',
    databaseURL: 'https://brigadist-29309-default-rtdb.firebaseio.com',
    storageBucket: 'brigadist-29309.firebasestorage.app',
    measurementId: 'G-SV10R168R4',
  );
}