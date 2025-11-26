import 'package:flutter/material.dart';
import 'package:forgotten_client/main_dev.dart' as dev;
import 'package:media_kit/media_kit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await dev.main();
}
