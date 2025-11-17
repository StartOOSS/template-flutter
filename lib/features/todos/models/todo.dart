class Todo {
  const Todo({
    required this.id,
    required this.title,
    required this.completed,
  });

  final String id;
  final String title;
  final bool completed;

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
        id: json['id'] as String,
        title: json['title'] as String,
        completed: json['completed'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'completed': completed,
      };

  Todo copyWith({String? title, bool? completed}) => Todo(
        id: id,
        title: title ?? this.title,
        completed: completed ?? this.completed,
      );
}
