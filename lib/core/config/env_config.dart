import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  const EnvConfig._();

  static Future<void> load() {
    return dotenv.load(fileName: '.env', isOptional: true);
  }

  static String get apiBaseUrl => dotenv.maybeGet('API_BASE_URL') ?? '';
}
