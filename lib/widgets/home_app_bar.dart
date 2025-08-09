import 'package:flutter/material.dart';
import '../screens/welcome_screen.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions; // ✅ allow custom actions (e.g., Done/X)
  const HomeAppBar({super.key, this.title, this.actions});

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
        icon: const Icon(Icons.home_outlined, color: Colors.black),
      ),
      actions: actions,
      title: title == null
          ? null
          : Text(title!, style: const TextStyle(color: Colors.black)),
      iconTheme: const IconThemeData(color: Colors.black),
    );
  }
}
