import '../entities/todo.dart';

abstract class TodoRepository {
  Future<TodoFetchResult> fetchTodos({bool forceRefresh = false});
  Future<Todo> addTodo(String title);
  Future<void> updateCompleted({required int id, required bool completed});
}

class TodoFetchResult {
  final List<Todo> todos;
  final String? lastSyncLabel;

  const TodoFetchResult({required this.todos, required this.lastSyncLabel});
}
