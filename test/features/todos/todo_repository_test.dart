import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:template_flutter/core/telemetry/telemetry.dart';
import 'package:template_flutter/features/todos/data/todo_api_client.dart';
import 'package:template_flutter/features/todos/data/todo_repository.dart';
import 'package:template_flutter/features/todos/models/todo.dart';

class _MockClient extends Mock implements http.Client {}

void main() {
  group('TodoRepository', () {
    late _MockClient client;
    late TodoRepository repository;

    setUpAll(() {
      registerFallbackValue(Uri.parse('http://localhost'));
    });

    setUp(() {
      client = _MockClient();
      Telemetry.httpClient = client;
      repository = TodoRepository(
          client: TodoApiClient(baseUrl: 'http://localhost:8080'));
    });

    test('lists todos', () async {
      when(() => client.get(any())).thenAnswer(
        (_) async => http.Response(
          jsonEncode([
            {'id': '1', 'title': 'Test', 'completed': false}
          ]),
          200,
        ),
      );

      final todos = await repository.listTodos();

      expect(todos, hasLength(1));
      expect(todos.first.title, 'Test');
    });

    test('creates todo', () async {
      when(() => client.post(any(),
          headers: any(named: 'headers'), body: any(named: 'body'))).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'id': '1', 'title': 'Created', 'completed': false}),
          201,
        ),
      );

      final todo = await repository.create('Created');

      expect(todo.title, 'Created');
    });

    test('toggles todo completion', () async {
      when(() => client.put(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'id': '1', 'title': 'Test', 'completed': true}),
          200,
        ),
      );

      final todo = await repository
          .toggleComplete(const Todo(id: '1', title: 'Test', completed: false));

      expect(todo.completed, isTrue);
      verify(() => client.put(any(),
          headers: any(named: 'headers'), body: any(named: 'body'))).called(1);
    });

    test('deletes todo', () async {
      when(() => client.delete(any()))
          .thenAnswer((_) async => http.Response('', 204));

      await repository.delete('1');

      verify(() => client.delete(any())).called(1);
    });
  });
}
