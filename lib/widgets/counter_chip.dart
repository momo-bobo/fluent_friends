import 'package:flutter/material.dart';

class CounterChip extends StatelessWidget {
  final int current;
  final int total;
  const CounterChip({super.key, required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Text(
          '$current of $total',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
