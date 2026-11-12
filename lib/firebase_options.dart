import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static const configured = true;

  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.iOS) return ios;
    throw UnsupportedError('모해 앱은 iOS에서 실행합니다.');
  }

  static const ios = FirebaseOptions(
    apiKey: 'AIzaSyBqvIQeSFlnOrAbWt7_JMCPUqFdc-dAIz8',
    appId: '1:282596382518:ios:ec0d2abfc77cce61398597',
    messagingSenderId: '282596382518',
    projectId: 'moa-club',
    storageBucket: 'moa-club.firebasestorage.app',
    iosBundleId: 'com.example.flutterProj',
  );
}
