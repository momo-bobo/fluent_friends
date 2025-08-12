import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // make sure flutter_svg is in pubspec
import '../screens/welcome_screen.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;

  /// Show the Home (leading) button.
  final bool showHomeLeading;

  /// Show the logo on the far right.
  final bool showLogo;

  /// Asset path to your logo (SVG or PNG).
  final String logoAssetPath;

  /// Logo height in the AppBar.
  final double logoHeight;

  /// Optional tap on the logo (defaults to no-op).
  final VoidCallback? onLogoTap;

  const HomeAppBar({
    super.key,
    this.title,
    this.actions,
    this.showHomeLeading = true,
    this.showLogo = true,
    this.logoAssetPath = 'assets/images/logo.svg',
    this.logoHeight = 28,
    this.onLogoTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final rightActions = <Widget>[
      if (actions != null) ...actions!,
      if (showLogo)
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: _Logo(
            assetPath: logoAssetPath,
            height: logoHeight,
            onTap: onLogoTap,
          ),
        ),
    ];

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: showHomeLeading
          ? IconButton(
              tooltip: 'Home',
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (_) => false,
                );
              },
              icon: const Icon(Icons.home_outlined, color: Colors.black),
            )
          : null,
      title: title == null
          ? null
          : Text(
              title!,
              style: const TextStyle(color: Colors.black),
            ),
      actions: rightActions,
      iconTheme: const IconThemeData(color: Colors.black),
    );
  }
}

class _Logo extends StatelessWidget {
  final String assetPath;
  final double height;
  final VoidCallback? onTap;

  const _Logo({
    required this.assetPath,
    required this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final img = assetPath.toLowerCase().endsWith('.svg')
        ? SvgPicture.asset(assetPath, height: height)
        : Image.asset(assetPath, height: height);

    return GestureDetector(
      onTap: onTap, // can be null (no-op)
      child: img,
    );
  }
}
