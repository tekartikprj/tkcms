import 'package:tekartik_app_http/app_http.dart';
import 'package:tkcms_common/src/firebase/firebase.dart';
import 'package:tkcms_common/src/flavor/flavor.dart';
import 'package:tkcms_common/tkcms_common.dart';
import 'package:tkcms_common/tkcms_firestore.dart';
import 'package:tkcms_common/tkcms_server.dart';

var functionCommandV2Dev = 'commandv2dev';
var functionCommandV2Prod = 'commandv2prod';

/// Callable function (when supported)
const callableFunctionCommandV2Dev = 'callcommandv2dev';
const callableFunctionCommandV2Prod = 'callcommandv2prod';

var functionDailyCronV2Dev = 'daylycronv2dev';
var functionDailyCronV2Prod = 'daylycronv2prod';

class TkCmsServerAppV2 implements TkCmsCommonServerApp {
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

  TkCmsServerAppV2({required this.context, required this.apiVersion}) {
    assert(apiVersion >= apiVersion2);
    initFunctions();
  }

  /// Default read config and call each app read
  Future<void> handleDailyCron() async {}

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

  HttpsFunction get commandV2 => functions.https.onRequestV2(
      HttpsOptions(cors: true, region: regionBelgium), onHttpsCommand);

  HttpsCallableFunction get callCommandV2 => functions.https.onCall(
      onCallableCommand,
      callableOptions: HttpsCallableOptions(region: regionBelgium, cors: true));

  Future<ApiResult> onCommand(ApiRequest apiRequest) async {
    switch (apiRequest.command.v!) {
      case commandTimestamp:
        return ApiGetTimestampResponse()
          ..timestamp.v = DateTime.timestamp().toIso8601String();
      case commandCron:
        await handleDailyCron();
        return ApiEmpty();
      default:
        throw UnsupportedError('command ${apiRequest.command.v!}');
    }
  }

  Future<Object> onCallableCommand(CallRequest request) async {
    try {
      var requestMap = request.dataAsMap;
      var apiRequest = requestMap.cv<ApiRequest>();
      var userId = request.context.auth?.uid;
      apiRequest.userId.v = userId;
      var result = await onCommand(apiRequest);

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

  Future<void> onHttpsCommand(ExpressHttpRequest request) async {
    try {
      var requestMap = request.bodyAsMap;
      var apiRequest = requestMap.cv<ApiRequest>();
      var result = await onCommand(apiRequest);

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
        command = functionCommandV2Prod;
        callCommand = callableFunctionCommandV2Prod;
        cron = functionDailyCronV2Prod;
        break;
      case FlavorContext.dev:
      case FlavorContext.devx:
      default:
        command = functionCommandV2Dev;
        callCommand = callableFunctionCommandV2Dev;
        cron = functionDailyCronV2Dev;
        break;
    }
    switch (apiVersion) {
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
