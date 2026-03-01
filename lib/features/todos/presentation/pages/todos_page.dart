import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/add_todo_dialog.dart';
import '../viewmodels/todo_viewmodel.dart';

class TodosPage extends StatefulWidget {
  const TodosPage({super.key});

  @override
  State<TodosPage> createState() => _TodosPageState();
}

class _TodosPageState extends State<TodosPage> {
  @override
  void initState() {
    super.initState();
    // Carrega ao abrir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TodoViewModel>().loadTodos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TodoViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: vm.isLoading
                ? null
                : () => vm.loadTodos(forceRefresh: true),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final title = await showDialog<String>(
            context: context,
            builder: (_) => const AddTodoDialog(),
          );
          if (title != null && title.trim().isNotEmpty) {
            await vm.addTodo(title.trim());
          }
        },
        child: const Icon(Icons.add),
      ),
      body: _body(vm),
    );
  }

  Widget _body(TodoViewModel vm) {
    if (vm.isLoading && vm.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.errorMessage != null && vm.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(vm.errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => vm.loadTodos(forceRefresh: true),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => vm.loadTodos(forceRefresh: true),
      child: ListView.separated(
        itemCount: vm.items.length + 1,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          if (i == 0) {
            final last = vm.lastSyncLabel ?? 'n/a';
            return ListTile(
              title: const Text('Última sincronização'),
              subtitle: Text(last),
            );
          }
          final todo = vm.items[i - 1];
          return CheckboxListTile(
            value: todo.completed,
            onChanged: (v) => vm.toggleCompleted(todo.id, v ?? false),
            title: Text(todo.title),
            subtitle: Text('ID: ${todo.id}'),
          );
        },
      ),
    );
  }
}
