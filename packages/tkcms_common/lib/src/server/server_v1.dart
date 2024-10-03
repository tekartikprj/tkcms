import 'package:tekartik_app_http/app_http.dart';
import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'package:tkcms_common/src/api/token_info.dart';
import 'package:tkcms_common/src/firebase/firebase.dart';
import 'package:tkcms_common/src/flavor/flavor.dart';
import 'package:tkcms_common/tkcms_api.dart';
import 'package:tkcms_common/tkcms_common.dart';
import 'package:tkcms_common/tkcms_firestore.dart';

// New V2 ff only
var functionCommandV1Dev = 'commandv1dev';
var functionCommandV1Prod = 'commandv1prod';

/// Callable function (when supported)
const callableFunctionCommandV1Dev = 'callcommandv1dev';
const callableFunctionCommandV1Prod = 'callcommandv1prod';

var functionDailyCronV1Dev = 'daylycronv1dev';
var functionDailyCronV1Prod = 'daylycronv1prod';

const timezoneEuropeParis = 'Europe/Paris';

const commandTimestamp = 'timestamp';
const commandProxy = 'proxy';
const commandCron = 'cron';
const commandInfo = 'info';
const commandInfoFb = 'infofb';

class CommandHandler {
  final TkCmsServerApp serverApp;
  final ExpressHttpRequest request;

  Future<void> sendErrorResponse(int statusCode, CvModel model) async {
    var res = request.response;
    res.statusCode = statusCode;
    res.headers.set(httpHeaderContentType, httpContentTypeJson);
    await res.send(model.toMap());
  }

  CommandHandler({required this.serverApp, required this.request});

  Future<void> sendResponse(CvModel model) async {
    var res = request.response;
    try {
      res.headers.set(httpHeaderContentType, httpContentTypeJson);
    } catch (_) {
      // This crashes in the emulator...
    }
    await res.send(model.toJson());
  }
}

class CronCommandHandler extends CommandHandler {
  CronCommandHandler({required super.request, required super.serverApp});

  // Read clientDateTime and return client and server date time
  Future<void> handle() async {
    // ignore: avoid_print
    print('cron');
    await serverApp.handleDailyCron();
    await sendResponse(ApiEmpty());
  }
}

class InfoCommandHandler extends CommandHandler {
  TokenInfo? _tokenInfo;

  TokenInfo? getTokenOrNull() =>
      _tokenInfo ??= TokenInfo.fromToken(request.headers.value(tokenHeader));

  Future<bool> requireToken() async {
    var tokenInfo = getTokenOrNull();
    if (tokenInfo?.serverDateTime == null) {
      await sendErrorResponse(httpStatusCodeForbidden,
          ApiErrorResponse()..message.v = 'Invalid token');
      return false;
    } else {
      var now = DateTime.timestamp();
      var secondDiff = now.difference(tokenInfo!.serverDateTime!).inSeconds;
      if (secondDiff > (isDebug ? 10 : 600)) {
        await sendErrorResponse(httpStatusCodeForbidden,
            ApiErrorResponse()..message.v = 'Token expired');
        return false;
      }
    }
    return true;
  }

  InfoCommandHandler({required super.request, required super.serverApp});

  // Read clientDateTime and return client and server date time
  Future<void> handle() async {
    var instanceCallCount = ++serverApp.instanceCallCount;
    var globalInstanceCallCount = ++TkCmsServerApp.globalInstanceCallCount;
    var info = ApiInfoResponse()
      ..uri.v = request.uri.toString()
      ..instanceCallCount.v = instanceCallCount
      ..globalInstanceCallCount.v = globalInstanceCallCount;
    //..version.v = appVersion.toString()
    //..debug.setValue(isDebug ? true : null)
    //..projectId.v = serverApp.projectId;
    try {} catch (_) {}
    await sendResponse(info);
  }
}

/// All fields must be present and non null
void ensureFields(CvModel model, CvFields fields) {
  for (var field in fields) {
    if (model.field(field.name)?.isNull ?? true) {
      throw ArgumentError('field ${field.name} missing or null in $model');
    }
  }
}

class GetTimeCommandHandler extends CommandHandler {
  GetTimeCommandHandler({required super.request, required super.serverApp});

  // Read clientDateTime and return client and server date time
  Future<void> handle() async {
    await sendResponse(ApiGetTimestampResponse()
      ..timestamp.v = DateTime.timestamp().toIso8601String());
  }
}

typedef TkCmsCreateServerAppFunction = TkCmsCommonServerApp Function(
    TkCmsServerAppContext context);

abstract interface class TkCmsCommonServerApp {
  int get apiVersion;
  void initFunctions();
  // v1 & v2
  String get command;
  // v2
  String get callCommand;
}

class TkCmsServerAppContext {
  /// Compat
  FirebaseFunctionsContext get firebaseFunctionsContext => firebaseContext;
  late final FirebaseContext firebaseContext;
  final FlavorContext flavorContext;

  TkCmsServerAppContext(
      {
      /// Compat
      FirebaseFunctionsContext? firebaseFunctionsContext,
      FirebaseContext? firebaseContext,
      required this.flavorContext})
      : firebaseContext = firebaseContext ?? firebaseFunctionsContext!;
}

/// Compat
typedef TkCmsServerApp = TkCmsServerAppV1;

class TkCmsServerAppV1 implements TkCmsCommonServerApp {
  @override
  final int apiVersion;
  final TkCmsServerAppContext context;
  int instanceCallCount = 0;
  static int globalInstanceCallCount = 0;

  FirebaseFunctionsContext get firebaseFunctionsContext =>
      context.firebaseFunctionsContext;

  FlavorContext get flavorContext => context.flavorContext;

  FirebaseContext get firebaseContext =>
      firebaseFunctionsContext.firebaseContext;

  FirebaseFunctions get functions => firebaseFunctionsContext.functions;

  late Uri commandUri;

  TkCmsServerAppV1({required this.context, this.apiVersion = apiVersion1}) {
    initFunctions();
  }

  Future<void> handle(ExpressHttpRequest request) async {
    var uri = request.uri;

    try {
      if (uri.pathSegments.isNotEmpty) {
        var command = uri.pathSegments.last;
        // devPrint('command: $command ($uri');
        switch (command) {
          case commandCron:
            await CronCommandHandler(
              serverApp: this,
              request: request,
            ).handle();
            return;
          case commandInfo:
            await InfoCommandHandler(serverApp: this, request: request)
                .handle();
            return;
        }
      }
      await handleDefault(request);
    } catch (e, st) {
      await sendErrorResponse(
          request,
          httpStatusCodeInternalServerError,
          ApiErrorResponse()
            ..message.v = e.toString()
            ..stackTrace.v = st.toString());
    }
  }

  /// Default read config and call each app read
  Future<void> handleDailyCron() async {}

  /// To override
  Future<bool> handleCustom(ExpressHttpRequest request) async {
    return false;
  }

  Future<bool> handleCore(ExpressHttpRequest request) async {
    var uri = request.uri;

    try {
      if (uri.pathSegments.isNotEmpty) {
        var command = uri.pathSegments.last;
        switch (command) {
          case commandCron:
            await CronCommandHandler(
              serverApp: this,
              request: request,
            ).handle();
            return true;

          case commandInfo:
            await InfoCommandHandler(serverApp: this, request: request)
                .handle();
            return true;
          case commandInfoFb:
            await GetInfoFbCommandHandler(
              firebaseContext: firebaseContext,
              request: request,
              serverApp: this,
            ).handle();
            return true;
          case commandTimestamp:
            await GetTimeCommandHandler(
              request: request,
              serverApp: this,
            ).handle();
            return true;
        }
      }
      return false;
    } catch (e, st) {
      await sendErrorResponse(
          request,
          httpStatusCodeInternalServerError,
          ApiErrorResponse()
            ..message.v = e.toString()
            ..stackTrace.v = st.toString());
      return true;
    }
  }

  Future<void> handleDefault(ExpressHttpRequest request) async {
    var uri = request.uri;

    try {
      await sendErrorResponse(request, httpStatusCodeInternalServerError,
          ApiErrorResponse()..message.v = 'Missing command in $uri');
    } catch (e, st) {
      await sendErrorResponse(
          request,
          httpStatusCodeInternalServerError,
          ApiErrorResponse()
            ..message.v = e.toString()
            ..stackTrace.v = st.toString());
    }
  }

  Firestore get firestore => firebaseContext.firestore;

  Future<void> dailyCronHandler(ScheduleEvent event) async {
    try {
      // ignore: avoid_print
      print(
          'dailyCron handler ${DateTime.now().toIso8601String()} ${event.jobName} ${event.scheduleTime}');
      try {
        await handleDailyCron();
      } catch (e) {
        // ignore: avoid_print
        print('cron dev error $e');
      }
      // ignore: avoid_print
      print('Cron done');
    } catch (e) {
      // ignore: avoid_print
      print('Cron Caught error $e');
    }
  }

  HttpsFunction get commandV1 => functions.https.onRequestV2(
      HttpsOptions(cors: true, region: regionBelgium), commandHttp);

  HttpsFunction get commandV2 => functions.https.onRequestV2(
      HttpsOptions(cors: true, region: regionBelgium), onHttpsCommandV2);

  HttpsCallableFunction get callCommandV2 => functions.https.onCall(
      onCallableCommandV2,
      callableOptions: HttpsCallableOptions(region: regionBelgium, cors: true));

  Future<ApiResult> onCommandV2(ApiRequest apiRequest) async {
    switch (apiRequest.command.v!) {
      case commandTimestamp:
        return ApiGetTimestampResponse()
          ..timestamp.v = DateTime.timestamp().toIso8601String();
      case commandCron:
        await handleDailyCron();
        return ApiEmpty();
      default:
        throw UnsupportedError('v1 command ${apiRequest.command.v!}');
    }
  }

  Future<Object> onCallableCommandV2(CallRequest request) async {
    try {
      var requestMap = request.dataAsMap;
      var apiRequest = requestMap.cv<ApiRequest>();
      var userId = request.context.auth?.uid;
      apiRequest.userId.v = userId;
      var result = await onCommandV2(apiRequest);

      return (ApiResponse()..result.v = (CvMapModel()..copyFrom(result)))
          .toMap();
    } on ApiException catch (e) {
      if (e.error != null) {
        return (ApiResponse()..error.v = e.error).toMap();
      } else {
        rethrow;
      }
    } catch (e, st) {
      if (isDebug) {
        // ignore: avoid_print
        print('Error $e');
        // ignore: avoid_print
        print(st);
      }
      //devPrint(st);
      throw HttpsError(HttpsErrorCode.internal, e.toString(), st.toString());
    }
  }

  Future<void> onHttpsCommandV2(ExpressHttpRequest request) async {
    try {
      var requestMap = request.bodyAsMap;
      var apiRequest = requestMap.cv<ApiRequest>();
      var result = await onCommandV2(apiRequest);

      await sendResponse(
          request, ApiResponse()..result.v = (CvMapModel()..copyFrom(result)));
    } on ApiException catch (e) {
      if (e.error != null) {
        await sendResponse(request, ApiResponse()..error.v = e.error);
      } else {
        rethrow;
      }
    } catch (e, st) {
      // devPrint(st);
      await sendCatchErrorResponse(request, e, st);
    }
  }

  Future<void> commandHttp(ExpressHttpRequest request) async {
    try {
      if (await handleCustom(request)) {
        return;
      }
      if (await handleCore(request)) {
        return;
      }

      await handleDefault(request);
    } catch (e, st) {
      // devPrint(st);
      await sendCatchErrorResponse(request, e, st);
    }
  }

  Future<void> sendCatchErrorResponse(
      ExpressHttpRequest request, dynamic e, StackTrace st) async {
    await sendErrorResponse(
        request,
        httpStatusCodeInternalServerError,
        ApiErrorResponse()
          ..message.v = e.toString()
          ..stackTrace.v = st.toString());
  }

  /// Send a response
  Future<void> sendResponse(ExpressHttpRequest request, CvModel model) async {
    var res = request.response;
    res.headers.set(httpHeaderContentType, httpContentTypeJson);
    await res.send(model.toMap());
  }

  Future<void> sendErrorResponse(
      ExpressHttpRequest request, int statusCode, CvModel model) async {
    var res = request.response;
    try {
      res.statusCode = statusCode;
    } catch (_) {}
    try {
      res.headers.set(httpHeaderContentType, httpContentTypeJson);
    } catch (_) {}

    await res.send(model.toMap());
  }

  @override
  late String command;
  @override
  late String callCommand;

  @override
  void initFunctions() {
    String cron;
    switch (flavorContext) {
      case FlavorContext.prod:
      case FlavorContext.prodx:
        command = functionCommandV1Prod;
        callCommand = callableFunctionCommandV1Prod;
        cron = functionDailyCronV1Prod;
        break;
      case FlavorContext.dev:
      case FlavorContext.devx:
      default:
        command = functionCommandV1Dev;
        callCommand = callableFunctionCommandV1Dev;
        cron = functionDailyCronV1Dev;
        break;
    }
    switch (apiVersion) {
      case apiVersion1:
        functions[command] = commandV1;
        break;
      case apiVersion2:
        functions[command] = commandV2;
        functions[callCommand] = callCommandV2;
        /*
    functions[callableCommand] = functions.https.onCall((request) {
    var userId = request.context.auth?.uid;
    var requestData = request.dataAsMap;
    var callableCommand = requestData.cv<ApiRequest>();
    var command = callableCommand.command.v!;
    var data = callableCommand.data.value;
    return onNotelioCommand(userId, command, data);
    },*/
        break;
      default:
        throw 'unsupported version $apiVersion';
    }

    if (!firebaseContext.local) {
      try {
        // Every day at 11pm
        functions[cron] = functions.scheduler.onSchedule(
            ScheduleOptions(
                schedule: '0 23 * * *',
                region: regionBelgium,
                timeZone: timezoneEuropeParis),
            dailyCronHandler);
      } catch (e, st) {
        if (isRunningAsJavascript) {
          // ignore: avoid_print
          print('error setup daily cron: $e');
          // ignore: avoid_print
          print(st);
        }
      }
    }
  }
}

class GetInfoFbCommandHandler extends CommandHandler {
  final FirebaseContext firebaseContext;

  GetInfoFbCommandHandler(
      {required this.firebaseContext,
      required super.request,
      required super.serverApp});

  // Read clientDateTime and return client and server date time
  Future<void> handle() async {
    await sendResponse(
        ApiInfoFbResponse()..projectId.v = firebaseContext.projectId);
  }
}
