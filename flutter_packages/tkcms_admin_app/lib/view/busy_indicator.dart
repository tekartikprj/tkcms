import 'package:flutter/material.dart';

class BusyIndicator extends StatelessWidget {
  const BusyIndicator({super.key, required this.busy});

  final ValueNotifier<bool> busy;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: busy,
      builder: (context, active, _) {
        if (active) {
          return const LinearProgressIndicator(
            // color: Colors.blue,
          );
        } else {
          return Container();
        }
      },
    );
  }
}
