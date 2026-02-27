import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/ui/app_root.dart';
import 'core/viewmodels/todo_viewmodel.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => TodoViewModel())],
      child: const AppRoot(),
    ),
  );
}
