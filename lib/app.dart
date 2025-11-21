import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
import 'core/telemetry/telemetry.dart';
import 'features/todos/presentation/todo_screen.dart';

class App extends StatelessWidget {
  const App({required this.config, super.key});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Template Flutter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      builder: (context, child) => child ?? const SizedBox.shrink(),
      navigatorObservers: [Telemetry.navigatorObserver],
      home: TodoScreen(config: config),
    );
  }
}
