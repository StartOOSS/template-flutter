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
  final config = AppConfig.fromEnv();
  await Telemetry.init(config);

  runApp(App(config: config));
}
