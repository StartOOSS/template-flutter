import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/telemetry/telemetry.dart';

const String _runtimeEnv =
    String.fromEnvironment('APP_ENV', defaultValue: 'mock');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final envFile = await _resolveEnvFile();
  await dotenv.load(fileName: envFile);

  try {
    final config = AppConfig.fromEnv(environment: _runtimeEnv);
    await Telemetry.init(config);
    runApp(App(config: config));
  } on ConfigValidationException catch (error) {
    stderr.writeln(
      'Configuration error: ${error.message}. Update your env files or see README.md.',
    );
    rethrow;
  }
}

Future<String> _resolveEnvFile() async {
  final candidates = ['.env.$_runtimeEnv', '.env', '.env.example'];
  for (final candidate in candidates) {
    if (await File(candidate).exists()) {
      return candidate;
    }
  }
  return '.env.example';
}
