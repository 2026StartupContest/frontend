import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_proj/app/app.dart';
import 'package:flutter_proj/core/config/env_config.dart';
import 'package:flutter_proj/data/services/auth_service.dart';
import 'package:flutter_proj/data/services/club_service.dart';
import 'package:flutter_proj/firebase_options.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:google_sign_in/google_sign_in.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvConfig.load();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  try {
    await GoogleSignIn.instance.initialize();
  } catch (_) {}
  final dependencies = MoaDependencies(
    auth: FirebaseAuthService(FirebaseAuth.instance),
    clubs: FirebaseClubService(
      FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'moa-db',
      ),
      FirebaseStorage.instance,
    ),
  );
  final uid = dependencies.auth.currentUid;
  // 오프라인 등으로 시작 정보를 못 불러와도 앱이 멈추지 않고 다시 시도 화면을 띄웁니다(#20).
  String initialRoute = AppRoutes.login;
  Object? initialArguments;
  if (uid != null) {
    try {
      final launch = await dependencies.clubs.launchFor(uid);
      initialRoute = launch.route;
      initialArguments = launch.arguments;
    } catch (error) {
      debugPrint('launchFor failed: $error');
      initialRoute = AppRoutes.launchRetry;
    }
  }
  runApp(
    MyApp(
      dependencies: dependencies,
      initialRoute: initialRoute,
      initialArguments: initialArguments,
    ),
  );
}
