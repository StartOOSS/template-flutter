import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/telemetry/telemetry.dart';
import '../models/todo.dart';

class TodoApiException implements Exception {
  TodoApiException({required this.message, this.statusCode, this.cause});

  final String message;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() =>
      'TodoApiException(statusCode: $statusCode, message: $message)';
}

class TodoApiClient {
  TodoApiClient({required String baseUrl, http.Client? client})
      : _baseUrl = baseUrl,
        _client = client;

  final String _baseUrl;
  final http.Client? _client;

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
  };

  http.Client get _resolvedClient => _client ?? Telemetry.httpClient;

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<List<Todo>> fetchTodos() => _guard('fetch todos', () async {
        final response = await _resolvedClient.get(_uri('/api/v1/todos'));
        if (response.statusCode != 200) {
          throw TodoApiException(
            message: 'Failed to fetch todos',
            statusCode: response.statusCode,
          );
        }
        final data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map((json) => Todo.fromJson(json as Map<String, dynamic>))
            .toList();
      });

  Future<Todo> createTodo(String title) => _guard('create todo', () async {
        final response = await _resolvedClient.post(
          _uri('/api/v1/todos'),
          headers: _jsonHeaders,
          body: jsonEncode({'title': title}),
        );
        if (response.statusCode != 201) {
          throw TodoApiException(
            message: 'Failed to create todo',
            statusCode: response.statusCode,
          );
        }
        return Todo.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      });

  Future<Todo> updateTodo(Todo todo) => _guard('update todo', () async {
        final response = await _resolvedClient.put(
          _uri('/api/v1/todos/${todo.id}'),
          headers: _jsonHeaders,
          body: jsonEncode(todo.toJson()),
        );
        if (response.statusCode != 200) {
          throw TodoApiException(
            message: 'Failed to update todo',
            statusCode: response.statusCode,
          );
        }
        return Todo.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      });

  Future<void> deleteTodo(String id) => _guard('delete todo', () async {
        final response =
            await _resolvedClient.delete(_uri('/api/v1/todos/$id'));
        if (response.statusCode != 204) {
          throw TodoApiException(
            message: 'Failed to delete todo',
            statusCode: response.statusCode,
          );
        }
      });

  Future<T> _guard<T>(String operation, Future<T> Function() run) async {
    try {
      return await run();
    } on TimeoutException catch (error) {
      throw TodoApiException(
        message: 'Request timed out while attempting to $operation.',
        cause: error,
      );
    } on http.ClientException catch (error) {
      throw TodoApiException(
        message: 'Network error while attempting to $operation.',
        cause: error,
      );
    }
  }
}
