import 'package:flutter/material.dart';

class SectionTile extends StatelessWidget {
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? titleLabel;

  const SectionTile({super.key, this.onTap, this.titleLabel, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return ListTile(
        dense: true,
        title: Text(titleLabel ?? '',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        onTap: onTap,
        onLongPress: onLongPress);
  }
}
