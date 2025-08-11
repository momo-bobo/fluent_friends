import 'package:flutter/material.dart';

class SpeakerToggle extends StatelessWidget {
  final bool autoplay;
  final ValueChanged<bool> onChanged;
  const SpeakerToggle({super.key, required this.autoplay, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget pill({required bool selected, required IconData icon, required VoidCallback onTap}) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: selected ? Colors.black : Colors.transparent, width: 3),
          ),
          child: Icon(icon, color: selected ? Colors.black : Colors.black45),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        pill(selected: autoplay, icon: Icons.volume_up_outlined, onTap: () => onChanged(true)),
        const SizedBox(width: 12),
        pill(selected: !autoplay, icon: Icons.volume_off_outlined, onTap: () => onChanged(false)),
      ],
    );
  }
}
