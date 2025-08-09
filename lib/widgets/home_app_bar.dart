import 'package:flutter/material.dart';
import '../screens/welcome_screen.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  const HomeAppBar({super.key, this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        tooltip: 'Home',
        onPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
            (_) => false,
          );
        },
        icon: const Icon(Icons.home, color: Colors.black),
      ),
      title: title == null
          ? null
          : Text(title!, style: const TextStyle(color: Colors.black)),
      iconTheme: const IconThemeData(color: Colors.black),
    );
  }
}
