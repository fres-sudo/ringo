import 'package:flutter/material.dart';

class RingoApp extends StatelessWidget {
  const RingoApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Ringo',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.indigo),
    home: const Scaffold(body: Center(child: Text('Ringo'))),
  );
}
