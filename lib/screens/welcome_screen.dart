import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fluent Friends')),
      body: const Center(
        child: Text(
          'Welcome to Fluent Friends!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
