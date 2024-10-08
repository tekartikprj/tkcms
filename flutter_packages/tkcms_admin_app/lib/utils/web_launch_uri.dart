import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

void webLaunchUri(Uri uri) {
  if (kDebugMode) {
    print(uri);
  }
  launchUrl(uri, webOnlyWindowName: '_blank');
}
