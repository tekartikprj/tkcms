import 'package:test/test.dart';
import 'package:tkcms_common/tkcms_api.dart';
import 'package:tkcms_common/tkcms_common.dart';

Future<void> main() async {
  test('time_service', () async {
    var timeService = TkCmsTimestampService.local();
    var now = await timeService.now();
    await sleep(300);
    var now2 = await timeService.now();
    expect(
      now2.millisecondsSinceEpoch - now.millisecondsSinceEpoch,
      closeTo(300, 50),
    );
  });
}
