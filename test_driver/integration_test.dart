import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// QA 재현 테스트가 찍은 화면을 QA_SHOT_DIR(기본: build/qa_screenshots)에 PNG로 저장합니다.
Future<void> main() {
  final dir = Platform.environment['QA_SHOT_DIR'] ?? 'build/qa_screenshots';
  return integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      final file = File('$dir/$name.png');
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);
      return true;
    },
  );
}
