import 'package:tkcms_common/firebase/firebase.dart';
import 'package:tkcms_common/tkcms_flavor.dart';

/// dev command
const functionCommandV2Dev = 'commandv2dev';

/// dev command (dart)
const functionCommandDartV2Dev = 'commanddartv2dev';

/// prod command
const functionCommandV2Prod = 'commandv2prod';

/// prod command (dart)
const functionCommandDartV2Prod = 'commanddartv2prod';

/// Callable function (when supported)
const callableFunctionCommandV2Dev = 'callcommandv2dev';

/// Callable function (dart)
const callableFunctionCommandDartV2Dev = 'callcommanddartv2dev';

/// prod command
const callableFunctionCommandV2Prod = 'callcommandv2prod';

/// prod command (dart)
const callableFunctionCommandDartV2Prod = 'callcommanddartv2prod';

/// Common server app interface.
abstract interface class TkCmsCommonServerApp {
  /// Api version.
  int get apiVersion;

  /// init functions.
  void initFunctions();
  // v1 & v2
  /// command.
  String get command;
  // v2
  /// callable command.
  String get callCommand;
}

/// Server app context.
class TkCmsServerAppContext {
  /// Compat
  FirebaseFunctionsContext get firebaseFunctionsContext => firebaseContext;

  /// Firebase context.
  late final FirebaseContext firebaseContext;

  /// Flavor context.
  final FlavorContext flavorContext;

  /// Server app context.
  TkCmsServerAppContext({
    /// Compat
    FirebaseFunctionsContext? firebaseFunctionsContext,
    FirebaseContext? firebaseContext,
    required this.flavorContext,
  }) : firebaseContext = firebaseContext ?? firebaseFunctionsContext!;
}
