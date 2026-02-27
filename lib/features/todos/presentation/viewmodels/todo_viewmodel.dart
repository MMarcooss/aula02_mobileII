import 'package:flutter/foundation.dart';
import '../../../todos/data/repositories/todo_repository_impl.dart';
import '../../data/repositories/todo_repository_impl.dart';
import '../../domain/entities/todo.dart';

class TodoViewModel extends ChangeNotifier {
  final TodoRepository _repo;
  TodoViewModel({TodoRepository? repo})
    : _repo = repo ?? TodoRepositoryImpl(); // bagunça: impl direto aqui

  bool isLoading = false;
  String? errorMessage;

  final List<Todo> items = [];
  String? lastSyncLabel;

  Future<void> loadTodos({bool forceRefresh = false}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _repo.fetchTodos(forceRefresh: forceRefresh);
      items
        ..clear()
        ..addAll(result.todos);
      lastSyncLabel = result.lastSyncLabel;
    } catch (e) {
      errorMessage = 'Falha ao carregar: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTodo(String title) async {
    // validação mínima fica no VM (ok)
    if (title.trim().isEmpty) {
      errorMessage = 'Título não pode ser vazio.';
      notifyListeners();
      return;
    }
    try {
      final created = await _repo.addTodo(title);
      items.insert(0, created);
      notifyListeners();
    } catch (e) {
      errorMessage = 'Falha ao adicionar: $e';
      notifyListeners();
    }
  }

  Future<void> toggleCompleted(int id, bool completed) async {
    final idx = items.indexWhere((t) => t.id == id);
    if (idx < 0) return;

    final old = items[idx];
    items[idx] = old.copyWith(completed: completed);
    notifyListeners();

    try {
      await _repo.updateCompleted(id: id, completed: completed);
    } catch (e) {
      // rollback
      items[idx] = old;
      errorMessage = 'Falha ao atualizar: $e';
      notifyListeners();
    }
  }
}
