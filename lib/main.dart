import 'package:flutter/material.dart';
import 'theme.dart';
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
      theme: AppTheme.light,
      home: const WelcomeScreen(),
    );
  }
}
