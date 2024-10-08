import 'package:flutter/material.dart';
import 'package:tekartik_app_date/calendar_time.dart';
import 'package:tkcms_admin_app/src/import_flutter.dart';

class DurationPicker extends StatefulWidget {
  final Duration? defaultValue;
  final BehaviorSubject<Duration?> subject;

  const DurationPicker({super.key, required this.subject, this.defaultValue});

  @override
  State<DurationPicker> createState() => _DurationPickerState();
}

extension on TimeOfDay {
  int get inSeconds => (hour * 60 + minute) * 60;
}

class _DurationPickerState extends State<DurationPicker> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueStreamBuilder(
        stream: widget.subject,
        builder: (context, snapshot) {
          var timestamp = snapshot.data;

          var time = CalendarTime(
              seconds: (timestamp ??
                      widget.defaultValue ??
                      const Duration(minutes: 30))
                  .inSeconds);

          return Row(
            children: [
              SizedBox(
                  width: 196,
                  child: ListTile(
                    onTap: () async {
                      var tod = TimeOfDay(
                          hour: time.fullHours, minute: time.hourMinutes);

                      var newTime = await showTimePicker(
                          context: context, initialTime: tod);
                      if (newTime != null) {
                        widget.subject
                            .add(Duration(seconds: newTime.inSeconds));
                      }
                    },
                    title: const Text('Duration'),
                    subtitle: Row(children: [
                      Text(time.text),
                      if (timestamp == null)
                        const Text('  default',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                            ))
                    ]),
                  ))
            ],
          );
        });
  }
}
