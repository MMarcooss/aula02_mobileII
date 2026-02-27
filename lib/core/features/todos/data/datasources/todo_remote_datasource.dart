import 'dart:convert';
import 'package:http/http.dart' as http;

import '../widgets/todo_model.dart';

class TodoRemoteDataSource {
  final http.Client _client;
  TodoRemoteDataSource([http.Client? client]) : _client = client ?? http.Client();

  Future<List<TodoModel>> fetchTodos() async {
    final uri = Uri.parse('https://jsonplaceholder.typicode.com/todos?_limit=20');
    final res = await _client.get(uri);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}');
    }

    final data = jsonDecode(res.body) as List;
    return data.map((e) => TodoModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<TodoModel> addTodo(String title) async {
    // JSONPlaceholder não cria de verdade, mas responde com um id
    final uri = Uri.parse('https://jsonplaceholder.typicode.com/todos');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': title, 'completed': false}),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}');
    }

    final obj = jsonDecode(res.body) as Map<String, dynamic>;
    return TodoModel.fromJson(obj);
  }

  Future<void> updateCompleted({required int id, required bool completed}) async {
    final uri = Uri.parse('https://jsonplaceholder.typicode.com/todos/$id');
    final res = await _client.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'completed': completed}),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}');
    }
  }
}
