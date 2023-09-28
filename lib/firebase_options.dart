// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCrvw-E_ex_dYnjEOADwxDRIkGC1eRIl5E',
    appId: '1:521448310776:android:7b696dee52cdc3feba380d',
    messagingSenderId: '521448310776',
    projectId: 'colla-chat',
    storageBucket: 'colla-chat.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBKnGn5IUnnyE13egP8JdNzlAmQunpVkbA',
    appId: '1:521448310776:ios:9231cdefc9c89573ba380d',
    messagingSenderId: '521448310776',
    projectId: 'colla-chat',
    storageBucket: 'colla-chat.appspot.com',
    iosBundleId: 'io.curltech.colla',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBKnGn5IUnnyE13egP8JdNzlAmQunpVkbA',
    appId: '1:521448310776:ios:9231cdefc9c89573ba380d',
    messagingSenderId: '521448310776',
    projectId: 'colla-chat',
    storageBucket: 'colla-chat.appspot.com',
    iosBundleId: 'io.curltech.colla',
  );
}