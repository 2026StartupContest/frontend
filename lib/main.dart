import 'package:flutter/material.dart';
import 'package:flutter_proj/app/app.dart';
import 'package:flutter_proj/core/config/env_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvConfig.load();
  runApp(const MyApp());
}
