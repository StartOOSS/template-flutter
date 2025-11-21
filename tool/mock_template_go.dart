import 'dart:async';
import 'dart:io';

import 'package:template_flutter/testing/mock_template_go_server.dart';

Future<void> main(List<String> args) async {
  var port = 5050;
  for (final arg in args) {
    if (arg.startsWith('--port=')) {
      final value = int.tryParse(arg.split('=').last);
      if (value != null) {
        port = value;
      }
    }
  }

  final server = await MockTemplateGoServer.start(port: port);
  stdout
    ..writeln('Mock template-go server running on ${server.baseUrl}')
    ..writeln('Press Ctrl+C to stop.');

  final completer = Completer<void>();

  void handleSignal(ProcessSignal signal) async {
    stdout.writeln('Received $signal, shutting down mock server...');
    await server.close();
    if (!completer.isCompleted) {
      completer.complete();
    }
  }

  ProcessSignal.sigint.watch().listen(handleSignal);
  ProcessSignal.sigterm.watch().listen(handleSignal);

  await completer.future;
}
