import 'package:flutter/material.dart';
import 'package:tekaly_firestore_explorer/firestore_explorer.dart';
import 'package:tekartik_app_date/calendar_day.dart';
import 'package:tekartik_app_date/calendar_time.dart';
import 'package:tkcms_admin_app/src/import_common.dart';
import 'package:tkcms_admin_app/src/import_flutter.dart';

class TimestampPicker extends StatefulWidget {
  final BehaviorSubject<Timestamp?> subject;

  const TimestampPicker({super.key, required this.subject});

  @override
  State<TimestampPicker> createState() => _TimestampPickerState();
}

class _TimestampPickerState extends State<TimestampPicker> {
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
          CalendarDay? day;
          CalendarTime? time;
          if (timestamp != null) {
            var localDateTime = timestamp.toDateTime(isUtc: false);
            day = CalendarDay.fromLocalDateTime(localDateTime);
            time = CalendarTime.fromDateTime(localDateTime);
          }

          return Row(
            children: [
              SizedBox(
                width: 154,
                child: ListTile(
                    onTap: () async {
                      var date =
                          day != null ? day.localDateTime : DateTime.now();
                      var dateTime = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate:
                            date.subtract(const Duration(days: 365 * 100)),
                        lastDate: date.add(const Duration(days: 365 * 100)),
                      );
                      if (dateTime != null) {
                        widget.subject.add(Timestamp.fromDateTime(
                            dayTimeToLocalDateTime(
                                CalendarDay.fromLocalDateTime(dateTime),
                                time ?? CalendarTime.zero())));
                      }
                    },
                    title: const Text(
                      'Date',
                      textScaler: TextScaler.noScaling,
                    ),
                    subtitle: Text(day != null ? day.text : '<no date>',
                        textScaler: TextScaler.noScaling),
                    trailing: const Icon(
                      Icons.edit,
                    )),
              ),
              SizedBox(
                  width: 154,
                  child: ListTile(
                    onTap: () async {
                      var tod = time != null
                          ? TimeOfDay(
                              hour: time.fullHours, minute: time.hourMinutes)
                          : TimeOfDay.now();
                      var newTime = await showTimePicker(
                          context: context, initialTime: tod);
                      if (newTime != null) {
                        widget.subject.add(Timestamp.fromDateTime(
                            dayTimeToLocalDateTime(
                                day ?? CalendarDay(dateTime: DateTime.now()),
                                CalendarTime(
                                    seconds:
                                        ((newTime.hour * 60) + newTime.minute) *
                                            60))));
                      }
                    },
                    title: const Text('Time', textScaler: TextScaler.noScaling),
                    subtitle: Text(time != null ? time.text : '<no time>',
                        textScaler: TextScaler.noScaling),
                    trailing: const Icon(
                      Icons.edit,
                    ),
                  ))
            ],
          );
        });
  }
}
