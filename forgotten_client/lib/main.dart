import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'main_dev.dart' as dev;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await dev.main();
}
