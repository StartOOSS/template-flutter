import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/telemetry/telemetry.dart';
import '../models/todo.dart';

class TodoApiClient {
  TodoApiClient({required String baseUrl, http.Client? client})
      : _baseUrl = baseUrl,
        _client = client ?? Telemetry.httpClient;

  final String _baseUrl;
  final http.Client _client;

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<List<Todo>> fetchTodos() async {
    final response = await _client.get(_uri('/api/v1/todos'));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch todos: ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((json) => Todo.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Todo> createTodo(String title) async {
    final response = await _client.post(
      _uri('/api/v1/todos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': title}),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create todo: ${response.statusCode}');
    }
    return Todo.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Todo> updateTodo(Todo todo) async {
    final response = await _client.put(
      _uri('/api/v1/todos/${todo.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(todo.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update todo: ${response.statusCode}');
    }
    return Todo.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> deleteTodo(String id) async {
    final response = await _client.delete(_uri('/api/v1/todos/$id'));
    if (response.statusCode != 204) {
      throw Exception('Failed to delete todo: ${response.statusCode}');
    }
  }
}
