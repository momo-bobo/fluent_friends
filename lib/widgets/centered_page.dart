import 'package:flutter/material.dart';

class CenteredPage extends StatelessWidget {
  final Widget child;
  final String? title;

  const CenteredPage({super.key, required this.child, this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title == null ? null : AppBar(title: Text(title!)),
      body: Container(
        color: Colors.white, // ✅ Clean white background
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
