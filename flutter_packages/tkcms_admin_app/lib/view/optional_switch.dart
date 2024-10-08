import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tekartik_app_rx_utils/app_rx_utils.dart';

class OptionalSwitch<T> extends StatefulWidget {
  final BehaviorSubject<T?> subject;
  final T? defaultValue;
  final Widget? child;
  final bool row;
  const OptionalSwitch(
      {super.key,
      required this.subject,
      this.child,
      this.defaultValue,
      this.row = true});

  @override
  State<OptionalSwitch<T>> createState() => _OptionalSwitchState<T>();
}

class _OptionalSwitchState<T> extends State<OptionalSwitch<T>> {
  final _switch = BehaviorSubject<bool>();
  late StreamSubscription _subscription;

  @override
  void initState() {
    _subscription = widget.subject.listen((value) {
      if (value != null) {
        _switch.value = true;
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueStreamBuilder<bool>(
        stream: _switch,
        builder: (context, snapshot) {
          var value = snapshot.data ?? false;
          var switchTile = SwitchListTile(
              value: value,
              onChanged: (newValue) {
                _switch.value = newValue;
                if (!newValue) {
                  widget.subject.add(null);
                } else {
                  if (widget.subject.valueOrNull == null) {
                    widget.subject.add(widget.defaultValue);
                  }
                }
              });
          if (widget.row && widget.child != null) {
            return Row(children: [
              Expanded(child: widget.child!),
              SizedBox(width: 128, child: switchTile)
            ]);
          }
          return Column(
            children: [switchTile, if (widget.child != null) widget.child!],
          );
        });
  }
}
