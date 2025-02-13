import 'package:flutter/material.dart';

import 'trailing_arrow.dart';

class InfoTile extends StatelessWidget {
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? titleLabel;
  final String? subtitleLabel;
  final Widget? trailing;
  final Widget? leading;
  const InfoTile({
    super.key,
    this.onTap,
    this.titleLabel,
    this.onLongPress,
    this.subtitleLabel,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      onLongPress: onLongPress,
      title: Text(titleLabel ?? ''),
      subtitle: subtitleLabel == null ? null : Text(subtitleLabel!),
      trailing: trailing ?? (onTap != null ? const TrailingArrow() : null),
      onTap: onTap,
    );
  }
}
