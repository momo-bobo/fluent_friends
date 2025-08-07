import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';

void main() {
  runApp(FluentFriendsApp());
}

class FluentFriendsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fluent Friends',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: WelcomeScreen(),
    );
  }
}