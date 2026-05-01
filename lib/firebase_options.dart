import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCXBqObyTZ6hfvQkGM_MQJ9NcA_MYIywmQ',
    appId: '1:861194761749:android:43ac7ff852a2074e13c01c',
    messagingSenderId: '861194761749',
    projectId: 'get-quran',
    storageBucket: 'get-quran.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD94_iHRfXsNBORgIdxKLJGQTNvoSzXPo4',
    appId: '1:861194761749:ios:83362027029aef2b13c01c',
    messagingSenderId: '861194761749',
    projectId: 'get-quran',
    storageBucket: 'get-quran.firebasestorage.app',
    iosClientId: null,
    iosBundleId: 'co.getquran.app',
  );
}
