import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tkcms_admin_app/src/import_flutter.dart';

class BusyIndicator extends StatelessWidget {
  const BusyIndicator({
    super.key,
    required this.busy,
  });

  final ValueStream<bool> busy;

  @override
  Widget build(BuildContext context) {
    return ValueStreamBuilder(
        stream: busy,
        builder: (context, snapshot) {
          if (snapshot.data ?? false) {
            return const LinearProgressIndicator(
                //color: Colors.blue,
                );
          } else {
            return Container();
          }
        });
  }
}
