import 'package:flutter/material.dart';

class AddTodoDialog extends StatefulWidget {
  const AddTodoDialog({super.key});

  @override
  State<AddTodoDialog> createState() => _AddTodoDialogState();
}

class _AddTodoDialogState extends State<AddTodoDialog> {
  final ctrl = TextEditingController();

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar TODO'),
      content: TextField(
        controller: ctrl,
        decoration: const InputDecoration(
          labelText: 'Título',
          hintText: 'Ex.: Comprar ração',
        ),
        autofocus: true,
        onSubmitted: (_) => _ok(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: _ok, child: const Text('Salvar')),
      ],
    );
  }

  void _ok() {
    Navigator.pop(context, ctrl.text);
  }
}
