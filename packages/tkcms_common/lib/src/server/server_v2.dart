import 'package:tkcms_common/src/flavor/flavor.dart';
import 'package:tkcms_common/tkcms_common.dart';
import 'package:tkcms_common/tkcms_firestore.dart';
import 'package:tkcms_common/tkcms_server.dart';

/// dev command
var functionCommandV2Dev = 'commandv2dev';

/// prod command
var functionCommandV2Prod = 'commandv2prod';

/// Callable function (when supported)
const callableFunctionCommandV2Dev = 'callcommandv2dev';

/// prod command
const callableFunctionCommandV2Prod = 'callcommandv2prod';

/// base options.
final baseCmsServerSecuredOptions = TkCmsApiSecuredOptions()
  ..add(apiCommandEcho, apiCommandEchoSecuredOptions)
  ..add(apiCommandEchoSecured, apiCommandEchoSecuredOptionsV2);

/// With app reference
class TkAppCmsServerAppBase extends TkCmsServerAppV2 {
  /// App name.
  final String app;

  /// App flavor context
  late final appFlavorContext = AppFlavorContext(
    flavorContext: flavorContext,
    app: app,
    local: this.firebaseContext.local,
  );

  /// Server app base.
  TkAppCmsServerAppBase(
    this.app, {
    super.version,
    required super.context,
    super.apiVersion = apiVersion2,
  });
}

/// Server app.
class TkCmsServerAppV2 implements TkCmsCommonServerApp {
  /// Secured options.
  final securedOptions = TkCmsApiSecuredOptions();

  /// version.
  final Version? version;

  /// To set to true in firebase function to force extra debug mode
  bool? debug;
  @override
  final int apiVersion;

  /// App context.
  final TkCmsServerAppContext context;

  /// Instance call count.
  int instanceCallCount = 0;

  /// Global call count.
  static int globalInstanceCallCount = 0;

  /// Firebase functions context.
  FirebaseFunctionsContext get firebaseFunctionsContext =>
      context.firebaseFunctionsContext;

  /// Flavor context.
  FlavorContext get flavorContext => context.flavorContext;

  /// Firebase context.
  FirebaseContext get firebaseContext =>
      firebaseFunctionsContext.firebaseContext;

  /// Firebase functions.
  FirebaseFunctions get functions => firebaseFunctionsContext.functions;

  /// Command uri.
  late Uri commandUri;

  /// Server app v2
  TkCmsServerAppV2({
    required this.context,
    required this.apiVersion,
    this.version,
  }) {
    assert(apiVersion >= apiVersion2);
    initApiBuilders();
    securedOptions.add(apiCommandEcho, apiCommandEchoSecuredOptions);
    securedOptions.timestampServiceOrNull = TkCmsTimestampService.local();
  }

  /// Firestore
  Firestore get firestore => firebaseContext.firestore;

  /// Command V2 Https function.
  HttpsFunction get commandV2 => functions.https.onRequestV2(
    HttpsOptions(cors: true, region: regionBelgium),
    onHttpsCommand,
  );

  /// Command V2 Https callable function.
  HttpsCallableFunction get callCommandV2 => functions.https.onCall(
    onCallableCommand,
    callableOptions: HttpsCallableOptions(region: regionBelgium, cors: true),
  );

  /// Handle secured command.
  Future<ApiResult> handleSecuredCommandRequest(ApiRequest apiRequest) async {
    try {
      var options = securedOptions.getOrThrow(
        apiRequest.securedInnerRequestCommand,
      );
      late ApiRequest innerRequest;
      if (options.version == apiSecuredEncOptionsVersion1) {
        innerRequest = securedOptions.unwrapSecuredRequest(apiRequest);
      } else if (options.version == apiSecuredEncOptionsVersion2) {
        // Handle missing timestamp as v1
        if (apiRequest.securedQueryTimestampOrNull == null) {
          innerRequest = securedOptions.unwrapSecuredRequest(apiRequest);
        } else {
          innerRequest = await securedOptions.unwrapSecuredRequestV2Async(
            apiRequest,
          );
        }
      } else {
        throw StateError('Invalid encoding options');
      }

      return onSecuredCommand(innerRequest);
    } catch (e, st) {
      if (isDebug) {
        // ignore: avoid_print
        print('handleSecuredCommand error $e');
        // ignore: avoid_print
        print(st);
      }
      rethrow;
    }
  }

  /// Handle command once unwrapped.
  Future<ApiResult> onSecuredCommand(ApiRequest apiRequest) async {
    switch (apiRequest.command.v!) {
      case apiCommandEcho:
        return onEchoCommand(apiRequest);
      default:
        throw UnsupportedError('secured command ${apiRequest.command.v!}');
    }
  }

  /// Echo for test.
  Future<ApiResult> onEchoCommand(ApiRequest apiRequest) async {
    var echoQuery = apiRequest.query<ApiEchoQuery>();
    return ApiEchoResult()
      ..data.v = echoQuery.data.v
      ..timestamp.v = echoQuery.timestamp.v;
  }

  /// Get info on the server.
  Future<ApiResult> onGetInfoCommand(ApiRequest apiRequest) async {
    var getInfoQuery = apiRequest.queryOrNull<ApiGetInfoQuery>();
    var debug = getInfoQuery?.debug.v ?? false;
    var app = apiRequest.app.v;

    var result = ApiGetInfoResult()
      ..app.setValue(app)
      ..version.setValue(version?.toString())
      ..projectId.setValue(firebaseContext.projectId);
    var instanceCallCount = ++this.instanceCallCount;
    var globalInstanceCallCount = ++TkCmsServerAppV2.globalInstanceCallCount;
    if (debug) {
      result
        ..instanceCallCount.setValue(instanceCallCount)
        ..globalInstanceCallCount.setValue(globalInstanceCallCount);
    }
    return result;
  }

  /// Cron command.
  Future<ApiResult> onCronCommand(ApiRequest apiRequest) async {
    return ApiEmpty();
  }

  /// Main command handler.
  Future<ApiResult> onCommand(ApiRequest apiRequest) async {
    var command = apiRequest.command.v!;
    switch (command) {
      case apiCommandEcho:
        return onEchoCommand(apiRequest);
      case apiCommandSecured:
        return handleSecuredCommandRequest(apiRequest);
      case commandTimestamp:
        return ApiGetTimestampResponse()
          ..timestamp.v = DateTime.timestamp().toIso8601String();
      case commandInfo:
        return await onGetInfoCommand(apiRequest);
      case commandCron:
        return await onCronCommand(apiRequest);

      default:
        throw UnsupportedError('command ${apiRequest.command.v!}');
    }
  }

  /// Callable command handler.
  Future<Object> onCallableCommand(CallRequest request) async {
    try {
      var requestMap = request.dataAsMap;
      var apiRequest = requestMap.cv<ApiRequest>();
      var userId = request.context.auth?.uid;
      apiRequest.userId.v = userId;
      var result = await onCommand(apiRequest);

      return (ApiResponse()..result.v = (CvMapModel()..copyFrom(result)))
          .toMap();
    } catch (e, st) {
      return apiResponseFromException(e, st: st, debug: debug).toMap();
    }
  }

  /// Https command handler
  Future<void> onHttpsCommand(ExpressHttpRequest request) async {
    try {
      var requestMap = request.bodyAsMap;
      var apiRequest = requestMap.cv<ApiRequest>();
      var result = await onCommand(apiRequest);

      await sendResponse(
        request,
        ApiResponse()..result.v = (CvMapModel()..copyFrom(result)),
      );
    } catch (e, st) {
      await sendResponse(
        request,
        apiResponseFromException(e, st: st, debug: debug),
      );
    }
  }

  /// Send catch response.
  Future<void> sendCatchErrorResponse(
    ExpressHttpRequest request,
    dynamic e,
    StackTrace st,
  ) async {
    await sendErrorResponse(
      request,
      httpStatusCodeInternalServerError,
      ApiErrorResponse()
        ..message.v = e.toString()
        ..stackTrace.v = st.toString(),
    );
  }

  /// Send a response
  Future<void> sendResponse(ExpressHttpRequest request, CvModel model) async {
    var res = request.response;
    res.headers.set(httpHeaderContentType, httpContentTypeJson);
    await res.send(model.toMap());
  }

  void _setHtmlContentType(ExpressHttpRequest request) {
    request.response.headers.add(
      'Cache-Control',
      'public, s-maxage=600, max-age=300',
    );
    _setHtmlContentTypeNoCache(request);
  }

  void _setHtmlContentTypeNoCache(ExpressHttpRequest request) {
    request.response.headers.add('Content-Type', 'text/html; charset=utf-8');
  }

  /// Send a response
  Future<void> sendHtml(ExpressHttpRequest request, String html) async {
    var res = request.response;
    _setHtmlContentType(request);

    const httpHeaderHtmlMimeTypeFixed = 'text/html; charset=utf-8';
    res.headers.set(httpHeaderContentType, httpHeaderHtmlMimeTypeFixed);
    await res.send(html);
  }

  /// Send error response.
  Future<void> sendErrorResponse(
    ExpressHttpRequest request,
    int statusCode,
    CvModel model,
  ) async {
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
    switch (flavorContext) {
      case FlavorContext.prod:
      case FlavorContext.prodx:
        command = functionCommandV2Prod;
        callCommand = callableFunctionCommandV2Prod;
        break;
      case FlavorContext.dev:
      case FlavorContext.devx:
      default:
        command = functionCommandV2Dev;
        callCommand = callableFunctionCommandV2Dev;
        break;
    }
    switch (apiVersion) {
      case apiVersion2:
        functions[command] = commandV2;
        functions[callCommand] = callCommandV2;
        break;
      default:
        throw 'unsupported version $apiVersion';
    }
  }
}
