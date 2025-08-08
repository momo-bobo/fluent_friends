import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';

void main() {
  runApp(const FluentFriendsApp());
}

class FluentFriendsApp extends StatelessWidget {
  const FluentFriendsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fluent Friends',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const WelcomeScreen(),
    );
  }
}
