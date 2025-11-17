import 'package:flutter/material.dart';

class TodoInput extends StatefulWidget {
  const TodoInput({required this.onSubmit, super.key});

  final Future<void> Function(String title) onSubmit;

  @override
  State<TodoInput> createState() => _TodoInputState();
}

class _TodoInputState extends State<TodoInput> {
  final TextEditingController _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    await widget.onSubmit(_controller.text.trim());
    _controller.clear();
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            key: const Key('todo-input-field'),
            decoration: const InputDecoration(
              labelText: 'Add todo',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          key: const Key('todo-submit-button'),
          onPressed: _submitting ? null : _submit,
          icon: const Icon(Icons.add),
          label: _submitting ? const Text('Adding...') : const Text('Add'),
        ),
      ],
    );
  }
}
