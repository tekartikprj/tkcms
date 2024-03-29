import 'package:tekartik_app_http/app_http.dart';
import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'package:tkcms_common/src/api/model/api_empty.dart';
import 'package:tkcms_common/src/api/model/api_error.dart';
import 'package:tkcms_common/src/api/model/api_info_response.dart';
import 'package:tkcms_common/src/api/token_info.dart';
import 'package:tkcms_common/src/firebase/firebase.dart';
import 'package:tkcms_common/src/flavor/flavor.dart';
import 'package:tkcms_common/tkcms_api.dart';
import 'package:tkcms_common/tkcms_common.dart';
import 'package:tkcms_common/tkcms_firestore.dart';

// New V2 ff only
var functionCommandV1Dev = 'commandv1dev';
var functionCommandV1Prod = 'commandv1prod';

var functionDailyCronV1Dev = 'daylycronv1dev';
var functionDailyCronV1Prod = 'daylycronv1prod';

const timezoneEuropeParis = 'Europe/Paris';

Model bodyAsMap(ExpressHttpRequest request) {
  return requestBodyAsJsonObject(request.body)!;
}

const commandTimestamp = 'timestamp';
const commandProxy = 'proxy';
const commandCron = 'cron';
const commandInfo = 'info';

class CommandHandler {
  final FfServerApp serverApp;
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
    var globalInstanceCallCount = ++FfServerApp.globalInstanceCallCount;
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
void ensureFields(CvModel model, List<CvField> fields) {
  for (var field in fields) {
    if (model.field(field.name)?.isNull ?? true) {
      throw ArgumentError('field ${field.name} missing or null in $model');
    }
  }
}

/*
class dCommandHandler {
  final ExpressHttpRequest request;


  /*
  // Check secure and auth token
  Future<bool> requireAuthToken({bool allowTest = false}) async {
    if (await requireToken()) {
      ApiUser? apiUser;
      try {
        if (tokenInfo!.userAuthToken != null) {
          apiUser =
              dcjoAuthTokenDecrypt(tokenInfo!.userAuthToken!).cv<ApiUser>();
        }
      } catch (e) {
        print('decrypt error: $e');
      }
      switch (apiUser?.role.v ?? '--none--') {
        case roleAnim:
        case roleAdmin:
        case roleSuperAdmin:
          break;
        case roleTest:
          if (allowTest) {
            break;
          }
        default:
          await sendErrorResponse(
              httpStatusCodeUnauthorized,
              ApiErrorResponse()
                ..message.v =
                    'Unauthorized - invalid user token${isDebug ? ' apiUser: $apiUser' : ''}');
          return false;
      }
      return true;
    }
    return false;
  }*/

  Future<void> sendErrorResponse(int statusCode, CvModel model) async {
    var res = request.response;
    res.statusCode = statusCode;
    res.headers.set(httpHeaderContentType, httpContentTypeJson);
    await res.send(model.toMap());
  }

  dCommandHandler({required this.request}) {
    initAllBuilders();
    tokenInfo = TokenInfo.fromToken(request.headers.value(tokenHeader));
  }

  Future<void> sendResponse(ExpressHttpRequest request, CvModel model) async {
    var res = request.response;
    res.headers.set(httpHeaderContentType, httpContentTypeJson);
    await res.send(model.toJson());
  }
}
*/

class GetTimeCommandHandler extends CommandHandler {
  GetTimeCommandHandler({required super.request, required super.serverApp});

  // Read clientDateTime and return client and server date time
  Future<void> handle() async {
    await sendResponse(ApiGetTimestampResponse()
      ..timestamp.v = DateTime.timestamp().toIso8601String());
  }
}

/*
/// All fields must be present and non null
void ensureFields(CvModel model, List<CvField> fields) {
  for (var field in fields) {
    if (model.field(field.name)?.isNull ?? true) {
      throw ArgumentError('field ${field.name} missing or null in $model');
    }
  }
}
*/
class FfServerApp {
  int instanceCallCount = 0;
  static int globalInstanceCallCount = 0;
  final FirebaseFunctionsContext firebaseFunctionsContext;
  final AppFlavorContext flavorContext;

  FirebaseFunctions get functionsV2 => firebaseFunctionsContext.functionsV2;

  late Uri commandUri;
  FirebaseFunctions get functionsV1 => firebaseFunctionsContext.functionsV1;
  String get app => flavorContext.app;
  late final databaseService = FfServerApp(
      firebaseFunctionsContext: firebaseFunctionsContext,
      flavorContext: flavorContext);

  FfServerApp(
      {required this.firebaseFunctionsContext, required this.flavorContext});

  Future<void> handle(ExpressHttpRequest request) async {
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

  Future<void> handleDailyCron() async {}

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

  Future<void> dailyCronHandler(ScheduleContext context) async {
    try {
      print('$app dailyCron handler ${DateTime.now().toIso8601String()}');
      try {
        await handleDailyCron();
      } catch (e) {
        print('cron dev error $e');
      }
      print('Cron done');
    } catch (e) {
      print('Cron Caught error $e');
    }
  }

  HttpsFunction get commandV1 => functionsV2.https.onRequestV2(
      HttpsOptions(cors: true, region: regionBelgium), commandHttp);

  Future<void> commandHttp(ExpressHttpRequest request) async {
    try {
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

  late String command;
  void initFunctions() {
    String cron;
    switch (flavorContext.flavorContext) {
      case FlavorContext.prod:
      case FlavorContext.prodx:
        command = functionCommandV1Prod;
        cron = functionDailyCronV1Prod;
        break;
      case FlavorContext.dev:
      case FlavorContext.devx:
      default:
        command = functionCommandV1Dev;
        cron = functionDailyCronV1Dev;
        break;
    }
    functionsV2[command] = commandV1;
    if (!flavorContext.local) {
      try {
        // Every day at 11pm
        functionsV2[cron] = functionsV1
            .region(regionBelgium)
            .pubsub
            .schedule('0 23 * * *')
            .timeZone(timezoneEuropeParis)
            .onRun(dailyCronHandler);
      } catch (e, st) {
        print('error setup daily cron: $e');
        print(st);
      }
    }
  }
}
