import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:template_flutter/app.dart';
import 'package:template_flutter/core/config/app_config.dart';
import 'package:template_flutter/core/telemetry/telemetry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const config = AppConfig(
    apiBaseUrl: 'http://localhost:8080',
    otelEndpoint: 'http://localhost:4318',
    serviceName: 'template-flutter-widget-test',
  );

  testWidgets('shows loading then renders todos', (tester) async {
    Telemetry.overrideHttpClient(
      MockClient((request) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return http.Response(
          jsonEncode([
            {'id': '1', 'title': 'Seed todo', 'completed': false}
          ]),
          200,
        );
      }),
    );

    await tester.pumpWidget(const App(config: config));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Seed todo'), findsOneWidget);
    expect(find.byKey(const Key('todo-input-field')), findsOneWidget);
  });

  testWidgets('shows error when initial load fails', (tester) async {
    Telemetry.overrideHttpClient(
      MockClient((_) async => http.Response('boom', 500)),
    );

    await tester.pumpWidget(const App(config: config));
    await tester.pumpAndSettle();

    expect(find.textContaining('Error:'), findsOneWidget);
  });

  testWidgets('pull-to-refresh fetches latest data', (tester) async {
    var responses = [
      http.Response(
        jsonEncode([
          {'id': '1', 'title': 'First', 'completed': false}
        ]),
        200,
      ),
      http.Response(
        jsonEncode([
          {'id': '2', 'title': 'Second', 'completed': false}
        ]),
        200,
      ),
    ];

    Telemetry.overrideHttpClient(
      MockClient((_) async => responses.isNotEmpty ? responses.removeAt(0) : http.Response('[]', 200)),
    );

    await tester.pumpWidget(const App(config: config));
    await tester.pumpAndSettle();

    expect(find.text('First'), findsOneWidget);

    await tester.drag(find.byType(Scrollable), const Offset(0, 300));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.pumpAndSettle();
    expect(find.text('Second'), findsOneWidget);
    expect(find.text('First'), findsNothing);
  });
}
