import 'package:flutter/material.dart';

class MemoraApp extends StatelessWidget {
  const MemoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Memora',
      home: Scaffold(body: Center(child: Text('Memora'))),
    );
  }
}
