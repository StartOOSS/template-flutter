import 'package:opentelemetry/api.dart';

import '../../../core/telemetry/telemetry.dart';
import '../models/todo.dart';
import 'todo_api_client.dart';

class TodoRepository {
  TodoRepository({required this.client});

  final TodoApiClient client;

  Future<List<Todo>> listTodos() => Telemetry.span('todo.list', (span) async {
        final todos = await client.fetchTodos();
        span.setAttribute(Attribute.fromInt('todo.count', todos.length));
        return todos;
      });

  Future<Todo> create(String title) => Telemetry.span('todo.create', (_) => client.createTodo(title));

  Future<Todo> toggleComplete(Todo todo) => Telemetry.span('todo.toggle', (_) {
        final updated = todo.copyWith(completed: !todo.completed);
        return client.updateTodo(updated);
      });

  Future<void> delete(String id) => Telemetry.span('todo.delete', (_) => client.deleteTodo(id));
}
