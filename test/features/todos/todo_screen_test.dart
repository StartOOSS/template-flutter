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

  late ErrorWidgetBuilder originalErrorBuilder;

  setUp(() {
    originalErrorBuilder = ErrorWidget.builder;
  });

  tearDown(() {
    ErrorWidget.builder = originalErrorBuilder;
  });

  const config = AppConfig(
    apiBaseUrl: 'http://localhost:8080',
    otelEndpoint: 'http://localhost:4318',
    serviceName: 'template-flutter-widget-test',
    environment: 'test',
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
      MockClient((_) async => responses.isNotEmpty
          ? responses.removeAt(0)
          : http.Response('[]', 200)),
    );

    await tester.pumpWidget(const App(config: config));
    await tester.pumpAndSettle();

    expect(find.text('First'), findsOneWidget);

    await tester.drag(find.byKey(const Key('todo-list')), const Offset(0, 300));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.pumpAndSettle();
    expect(find.text('Second'), findsOneWidget);
    expect(find.text('First'), findsNothing);
  });

  testWidgets('performs create, toggle, and delete flows', (tester) async {
    final todos = <Map<String, dynamic>>[
      {'id': '1', 'title': 'Existing', 'completed': false},
    ];

    Telemetry.overrideHttpClient(
      MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(jsonEncode(todos), 200);
        }
        if (request.method == 'POST') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final created = {
            'id': '${todos.length + 1}',
            ...body,
            'completed': false
          };
          todos.insert(0, created);
          return http.Response(jsonEncode(created), 201);
        }
        if (request.method == 'PUT') {
          final id = request.url.pathSegments.last;
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final index = todos.indexWhere((t) => t['id'] == id);
          todos[index] = {...todos[index], ...body};
          return http.Response(jsonEncode(todos[index]), 200);
        }
        if (request.method == 'DELETE') {
          final id = request.url.pathSegments.last;
          todos.removeWhere((t) => t['id'] == id);
          return http.Response('', 204);
        }

        return http.Response('Unhandled', 500);
      }),
    );

    await tester.pumpWidget(const App(config: config));
    await tester.pumpAndSettle();

    expect(find.text('Existing'), findsOneWidget);

    await tester.enterText(
        find.byKey(const Key('todo-input-field')), 'New todo');
    await tester.tap(find.byKey(const Key('todo-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('New todo'), findsOneWidget);

    await tester.tap(find.byKey(const Key('todo-2-checkbox')));
    await tester.pumpAndSettle();
    final toggledTile = find.ancestor(
        of: find.text('New todo'), matching: find.byType(ListTile));
    final textWidget = tester.widget<Text>(
        find.descendant(of: toggledTile, matching: find.byType(Text)).first);
    expect(textWidget.style?.decoration, TextDecoration.lineThrough);

    await tester.tap(find.byKey(const Key('todo-2-delete')));
    await tester.pumpAndSettle();

    expect(find.text('New todo'), findsNothing);
    expect(find.text('Existing'), findsOneWidget);
  });
}
