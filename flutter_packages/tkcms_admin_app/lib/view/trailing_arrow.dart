import 'package:flutter/material.dart';

class TrailingArrow extends StatelessWidget {
  final Color? color;
  const TrailingArrow({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.arrow_forward_ios, color: color);
  }
}
