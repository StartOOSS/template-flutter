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

  Future<Todo> create(String title) =>
      Telemetry.span('todo.create', (span) async {
        final todo = await client.createTodo(title);
        span.addEvent(
          'todo.created',
          attributes: [
            Attribute.fromString('todo.id', todo.id),
            Attribute.fromString('todo.title', todo.title),
          ],
        );
        return todo;
      });

  Future<Todo> toggleComplete(Todo todo) =>
      Telemetry.span('todo.toggle', (span) async {
        final updated = todo.copyWith(completed: !todo.completed);
        final response = await client.updateTodo(updated);
        span.addEvent(
          'todo.toggled',
          attributes: [
            Attribute.fromString('todo.id', response.id),
            Attribute.fromBoolean('todo.completed', response.completed),
          ],
        );
        return response;
      });

  Future<void> delete(String id) => Telemetry.span('todo.delete', (span) async {
        await client.deleteTodo(id);
        span.addEvent(
          'todo.deleted',
          attributes: [Attribute.fromString('todo.id', id)],
        );
      });
}
