import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/telemetry/telemetry.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final envFile = File('.env');
  final fileName = await envFile.exists() ? '.env' : '.env.example';
  await dotenv.load(fileName: fileName);

  try {
    final config = AppConfig.fromEnv();
    await Telemetry.init(config);
    runApp(App(config: config));
  } on ConfigValidationException catch (error) {
    stderr.writeln(
      'Configuration error: ${error.message}. Update your .env or see README.md.',
    );
    rethrow;
  }
}
