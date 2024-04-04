import 'package:flutter/material.dart';

import 'trailing_arrow.dart';

class GoToTile extends StatelessWidget {
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final String? titleLabel;
  final String? subtitleLabel;
  final bool? important;
  const GoToTile(
      {super.key,
      required this.onTap,
      this.titleLabel,
      this.onLongPress,
      this.subtitleLabel,
      this.important});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onLongPress: onLongPress,
      title: Text(titleLabel ?? '',
          style: TextStyle(
            //color: colorBlack,
            fontSize: (important ?? false) ? 22 : null,
            fontWeight: (important ?? false) ? FontWeight.w900 : null,
          )),
      subtitle: subtitleLabel == null ? null : Text(subtitleLabel!),
      trailing: const TrailingArrow(),
      onTap: onTap,
    );
  }
}
