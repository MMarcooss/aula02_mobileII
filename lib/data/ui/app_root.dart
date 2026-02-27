import 'package:flutter/material.dart';

import '../../template/screens/todos_page.dart';

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TODO Refatoração',
      theme: ThemeData(useMaterial3: true),
      home: const TodosPage(),
    );
  }
}
