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
  final launch = uid == null ? null : await dependencies.clubs.launchFor(uid);
  runApp(
    MyApp(
      dependencies: dependencies,
      initialRoute: launch?.route ?? AppRoutes.login,
      initialArguments: launch?.arguments,
    ),
  );
}
