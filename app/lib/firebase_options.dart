import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAHG51RGnIDD-16jpgyBY38eU3WnTxdpeY',
    appId: '1:648404388408:android:0c4f6e635f44544ad634cd',
    messagingSenderId: '648404388408',
    projectId: 'rupayan-81953',
    storageBucket: 'rupayan-81953.firebasestorage.app',
  );

  // iOS and macOS use the same Firebase project — update these values
  // once you add GoogleService-Info.plist from Firebase Console
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAHG51RGnIDD-16jpgyBY38eU3WnTxdpeY',
    appId: '1:648404388408:android:0c4f6e635f44544ad634cd',
    messagingSenderId: '648404388408',
    projectId: 'rupayan-81953',
    storageBucket: 'rupayan-81953.firebasestorage.app',
    iosBundleId: 'com.sitesync.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAHG51RGnIDD-16jpgyBY38eU3WnTxdpeY',
    appId: '1:648404388408:android:0c4f6e635f44544ad634cd',
    messagingSenderId: '648404388408',
    projectId: 'rupayan-81953',
    storageBucket: 'rupayan-81953.firebasestorage.app',
    iosBundleId: 'com.sitesync.app',
  );
}
