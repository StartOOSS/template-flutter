import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:integration_test/integration_test.dart';

import 'package:template_flutter/app.dart';
import 'package:template_flutter/core/config/app_config.dart';
import 'package:template_flutter/core/telemetry/telemetry.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('todo e2e flow with telemetry-enabled HTTP client', (tester) async {
    final todos = <Map<String, dynamic>>[
      {'id': '1', 'title': 'Seed todo', 'completed': false},
    ];

    final client = MockClient((request) async {
      if (request.url.path == '/api/v1/todos' && request.method == 'GET') {
        return http.Response(jsonEncode(todos), 200);
      }

      if (request.url.path == '/api/v1/todos' && request.method == 'POST') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final created = {
          'id': '${todos.length + 1}',
          'title': body['title'],
          'completed': false,
        };
        todos.insert(0, created);
        return http.Response(jsonEncode(created), 201);
      }

      if (request.url.path.startsWith('/api/v1/todos/') && request.method == 'PUT') {
        final id = request.url.pathSegments.last;
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final index = todos.indexWhere((t) => t['id'] == id);
        if (index == -1) {
          return http.Response('Not found', 404);
        }
        final updated = {
          'id': id,
          'title': body['title'],
          'completed': body['completed'],
        };
        todos[index] = updated;
        return http.Response(jsonEncode(updated), 200);
      }

      if (request.url.path.startsWith('/api/v1/todos/') && request.method == 'DELETE') {
        final id = request.url.pathSegments.last;
        todos.removeWhere((t) => t['id'] == id);
        return http.Response('', 204);
      }

      return http.Response('Unhandled ${request.method} ${request.url}', 500);
    });

    const config = AppConfig(
      apiBaseUrl: 'http://localhost:8080',
      otelEndpoint: 'http://localhost:4318',
      serviceName: 'template-flutter-e2e',
    );

    await Telemetry.init(config, client: client, enableExporters: false);

    await tester.pumpWidget(const App(config: config));
    await tester.pumpAndSettle();

    expect(find.text('Seed todo'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('todo-input-field')), 'Write e2e test');
    await tester.tap(find.byKey(const Key('todo-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Write e2e test'), findsOneWidget);

    await tester.tap(find.byKey(const Key('todo-2-checkbox')));
    await tester.pumpAndSettle();
    final completedTile = find.ancestor(
      of: find.text('Write e2e test'),
      matching: find.byType(ListTile),
    );
    final textWidget = tester.widget<Text>(find.descendant(of: completedTile, matching: find.byType(Text)).first);
    expect(textWidget.style?.decoration, TextDecoration.lineThrough);

    await tester.tap(find.byKey(const Key('todo-2-delete')));
    await tester.pumpAndSettle();

    expect(find.text('Write e2e test'), findsNothing);
  });
}
