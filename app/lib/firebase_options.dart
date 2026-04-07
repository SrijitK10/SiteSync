import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

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
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
      default:
        // Assume web if not mobile/desktop
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBs3e8m1l2CpdzQvmgZcXVAwB454KjlQlg',
    appId: '1:648404388408:web:dc86d54ad332e9e4d634cd',
    messagingSenderId: '648404388408',
    projectId: 'rupayan-81953',
    authDomain: 'rupayan-81953.firebaseapp.com',
    storageBucket: 'rupayan-81953.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAHG51RGnIDD-16jpgyBY38eU3WnTxdpeY',
    appId: '1:648404388408:android:0c4f6e635f44544ad634cd',
    messagingSenderId: '648404388408',
    projectId: 'rupayan-81953',
    storageBucket: 'rupayan-81953.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDK-J4JlVaRQFQvO2bqKoBNPEluC652J7E',
    appId: '1:648404388408:ios:ccd834623157cbf5d634cd',
    messagingSenderId: '648404388408',
    projectId: 'rupayan-81953',
    storageBucket: 'rupayan-81953.firebasestorage.app',
    iosBundleId: 'com.sitesync.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDK-J4JlVaRQFQvO2bqKoBNPEluC652J7E',
    appId: '1:648404388408:ios:ccd834623157cbf5d634cd',
    messagingSenderId: '648404388408',
    projectId: 'rupayan-81953',
    storageBucket: 'rupayan-81953.firebasestorage.app',
    iosBundleId: 'com.sitesync.app',
  );
}
