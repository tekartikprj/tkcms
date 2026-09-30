# Subject bound editors (tkcms_admin_app)

`OptionalSwitch`, `TimestampPicker` and `DurationPicker` (one file each under
`package:tkcms_admin_app/view/`) edit a rxdart `BehaviorSubject` in place:
the subject is the form state, `null` means unset, and the screen reads
`subject.valueOrNull` when saving. Seed the subjects and register them for
disposal (`audiAddBehaviorSubject` in an `AutoDisposeBaseState`, or close
them in `dispose`).

* `OptionalSwitch<T>(subject: BehaviorSubject<T?>, defaultValue:, child:,
  row: true)`: a `SwitchListTile` beside `child` (`row: false` stacks the
  switch above it). Turning it off adds `null` to the subject; turning it on
  adds `defaultValue` when the subject holds null. The switch also turns
  itself on whenever the subject receives a non null value, so an editor
  child that writes the subject keeps the switch consistent.
* `TimestampPicker(subject: BehaviorSubject<Timestamp?>)`: a "Date" tile
  (`showDatePicker`, a hundred years each way) and a "Time" tile
  (`showTimePicker`) in local time. Each pick keeps the other half: a date
  picked with no time gives midnight, a time picked with no date uses today.
  Shows `<no date>` / `<no time>` while null. `Timestamp` is the firestore
  one re-exported by `tkcms_common/tkcms_firestore.dart`.
* `DurationPicker(subject: BehaviorSubject<Duration?>, defaultValue:)`: one
  "Duration" tile using the time picker as hours:minutes (23h59 at most).
  While the subject is null it displays `defaultValue` (30 minutes when
  null too) followed by an italic "default"; a pick writes the duration.

```dart
import 'package:flutter/material.dart';
import 'package:tkcms_admin_app/audi/tkcms_audi.dart';
import 'package:tkcms_admin_app/view/body_container.dart';
import 'package:tkcms_admin_app/view/duration_picker.dart';
import 'package:tkcms_admin_app/view/info_tile.dart';
import 'package:tkcms_admin_app/view/optional_switch.dart';
import 'package:tkcms_admin_app/view/timestamp_picker.dart';
import 'package:tkcms_common/tkcms_firestore.dart';

class ScheduleScreen extends StatefulWidget {
  final Timestamp? initialStart;
  const ScheduleScreen({super.key, this.initialStart});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends AutoDisposeBaseState<ScheduleScreen> {
  // Seeded so the value is always readable; disposed with the state.
  late final start = audiAddBehaviorSubject(
    BehaviorSubject<Timestamp?>.seeded(widget.initialStart),
  );
  late final duration = audiAddBehaviorSubject(
    BehaviorSubject<Duration?>.seeded(null),
  );

  void _save() {
    // null when the switch is off or nothing was picked.
    var startValue = start.valueOrNull;
    var durationValue = duration.valueOrNull ?? const Duration(minutes: 30);
    debugPrint('start $startValue duration $durationValue');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule')),
      body: ListView(
        children: [
          BodyContainer(
            child: Column(
              children: [
                // Off clears the subject, on restores the default.
                OptionalSwitch<Timestamp>(
                  subject: start,
                  defaultValue: Timestamp.fromDateTime(DateTime.now()),
                  child: TimestampPicker(subject: start),
                ),
                OptionalSwitch<Duration>(
                  subject: duration,
                  defaultValue: const Duration(hours: 1),
                  row: false,
                  child: DurationPicker(
                    subject: duration,
                    defaultValue: const Duration(minutes: 30),
                  ),
                ),
                const InfoTile(titleLabel: 'Times are local'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _save,
        child: const Icon(Icons.save),
      ),
    );
  }
}
```
