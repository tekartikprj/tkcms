import 'package:flutter/material.dart';
import 'package:tkcms_admin_app/src/import_common.dart';
import 'package:tkcms_admin_app/utils/version_utils.dart';

class VersionTile extends StatelessWidget {
  const VersionTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('Version'),
        ],
      ),
      subtitle: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FutureBuilder<Version>(
              future: getAppVersion(),
              builder: (context, snapshot) {
                var version = snapshot.data;
                if (version == null) {
                  return const Text('');
                }
                return Text(
                    '$version'); // (${gAppService.app} - ${gAppService.appType}${gAppService.isLocal ? ' - local' : ''})');
              }),
        ],
      ),
    );
  }
}
