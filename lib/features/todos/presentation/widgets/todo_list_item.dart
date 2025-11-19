import 'package:flutter/material.dart';

import '../../models/todo.dart';

class TodoListItem extends StatelessWidget {
  const TodoListItem({
    required this.todo,
    required this.animation,
    required this.onToggle,
    required this.onDelete,
    super.key,
  });

  final Todo todo;
  final Animation<double> animation;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: animation,
      child: ListTile(
        leading: Checkbox(
          key: Key('todo-${todo.id}-checkbox'),
          value: todo.completed,
          onChanged: (_) => onToggle(),
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: todo.completed ? TextDecoration.lineThrough : null,
          ),
        ),
        trailing: IconButton(
          key: Key('todo-${todo.id}-delete'),
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }
}
