import 'package:flutter/material.dart';

import '../data/todo_repository.dart';
import '../data/todo_api_client.dart';
import '../models/todo.dart';
import 'widgets/todo_input.dart';
import 'widgets/todo_list_item.dart';
import '../../../core/telemetry/telemetry.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key, required this.config});

  final dynamic config;

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  late final TodoRepository _repository;
  late Future<List<Todo>> _initialLoad;
  final _listKey = GlobalKey<AnimatedListState>();
  final _todos = <Todo>[];

  @override
  void initState() {
    super.initState();
    _repository = TodoRepository(
      client: TodoApiClient(
        baseUrl: widget.config.apiBaseUrl,
        client: Telemetry.httpClient,
      ),
    );
    _initialLoad = _loadTodos();
  }

  Future<List<Todo>> _loadTodos() async {
    final todos = await _repository.listTodos();
    _todos
      ..clear()
      ..addAll(todos);
    return _todos;
  }

  Future<void> _refresh() async {
    await _loadTodos();
    setState(() {});
  }

  Future<void> _createTodo(String title) async {
    final newTodo = await _repository.create(title);
    _todos.insert(0, newTodo);
    _listKey.currentState?.insertItem(0);
    setState(() {});
  }

  Future<void> _toggle(Todo todo) async {
    final updated = await _repository.toggleComplete(todo);
    final index = _todos.indexWhere((t) => t.id == todo.id);
    if (index != -1) {
      setState(() {
        _todos[index] = updated;
      });
    }
  }

  Future<void> _delete(Todo todo) async {
    final index = _todos.indexWhere((t) => t.id == todo.id);
    if (index == -1) return;
    final removed = _todos.removeAt(index);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => TodoListItem(
        todo: removed,
        animation: animation,
        onToggle: () {},
        onDelete: () {},
      ),
    );
    await _repository.delete(todo.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Template Todo'),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Todo>>(
          future: _initialLoad,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: TodoInput(onSubmit: _createTodo),
                  ),
                  Expanded(
                    child: KeyedSubtree(
                      key: const Key('todo-list'),
                      child: AnimatedList(
                        key: _listKey,
                        initialItemCount: _todos.length,
                        itemBuilder: (context, index, animation) {
                          final todo = _todos[index];
                          return TodoListItem(
                            todo: todo,
                            animation: animation,
                            onToggle: () => _toggle(todo),
                            onDelete: () => _delete(todo),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
