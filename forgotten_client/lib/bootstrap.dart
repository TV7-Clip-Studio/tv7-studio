import 'package:flutter/widgets.dart';

import 'app.dart';
import 'config/app_config.dart';

Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App(config: config));
}
