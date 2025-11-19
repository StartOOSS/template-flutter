import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:template_flutter/core/telemetry/telemetry.dart';
import 'package:template_flutter/features/todos/data/todo_api_client.dart';
import 'package:template_flutter/features/todos/models/todo.dart';

void main() {
  group('TodoApiClient', () {
    test('fetches todos and parses json', () async {
      Telemetry.overrideHttpClient(
        MockClient(
          (request) async => http.Response(
            jsonEncode([
              {'id': '1', 'title': 'Test', 'completed': false},
            ]),
            200,
          ),
        ),
      );

      final client = TodoApiClient(baseUrl: 'http://example.com');
      final todos = await client.fetchTodos();

      expect(todos, hasLength(1));
      expect(todos.first, isA<Todo>());
      expect(todos.first.title, 'Test');
    });

    test('throws when fetch fails', () async {
      Telemetry.overrideHttpClient(
        MockClient((_) async => http.Response('nope', 500)),
      );
      final client = TodoApiClient(baseUrl: 'http://example.com');

      expect(
        () => client.fetchTodos(),
        throwsA(isA<Exception>()),
      );
    });

    test('creates todo with correct payload', () async {
      late http.Request captured;
      Telemetry.overrideHttpClient(
        MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({'id': '2', 'title': 'New', 'completed': false}),
            201,
          );
        }),
      );

      final client = TodoApiClient(baseUrl: 'http://example.com');
      final todo = await client.createTodo('New');

      expect(todo.title, 'New');
      expect(captured.headers['Content-Type'], 'application/json');
      expect(jsonDecode(captured.body), {'title': 'New'});
    });

    test('updates todo and returns parsed object', () async {
      Telemetry.overrideHttpClient(
        MockClient((request) async {
          final payload = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({...payload, 'title': 'Updated'}),
            200,
          );
        }),
      );

      final client = TodoApiClient(baseUrl: 'http://example.com');
      final updated = await client.updateTodo(
        const Todo(id: '1', title: 'Old', completed: false),
      );

      expect(updated.title, 'Updated');
      expect(updated.completed, isFalse);
    });

    test('deletes todo and errors on non-204', () async {
      Telemetry.overrideHttpClient(
        MockClient((request) async => http.Response('', 204)),
      );
      final client = TodoApiClient(baseUrl: 'http://example.com');

      await client.deleteTodo('1');

      Telemetry.overrideHttpClient(
        MockClient((_) async => http.Response('', 500)),
      );
      expect(
        () => client.deleteTodo('1'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
