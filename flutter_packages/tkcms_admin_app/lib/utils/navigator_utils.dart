import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tekartik_app_navigator_flutter/content_navigator.dart';

var debugNavigation = kDebugMode;

void popToRootScreen(BuildContext context) {
  if (debugNavigation) {
    // ignore: avoid_print
    print('popToRootScreen()');
  }
  ContentNavigator.popUntilPathOrPush(context, rootContentPath);
}

Future<T?> appPushPath<T>(BuildContext context, ContentPath path,
    {Object? arguments, TransitionDelegate? transitionDelegate}) async {
  if (debugNavigation) {
    // ignore: avoid_print
    print('pushPath: ${path.routeSettings(arguments)}');
  }
  return await ContentNavigator.of(context).push<T>(
      path.routeSettings(arguments),
      transitionDelegate: transitionDelegate);
}
