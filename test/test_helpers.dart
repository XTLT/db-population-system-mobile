import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:population_mobile/api/api_client.dart';

/// ============================================================
/// 共享测试基建（本次测试专用，不修改任何 lib/ 业务代码）
///
/// 注入原理：ApiClient 是单例，其 `dio` 是公开 getter。
/// 所有 *Api 类都通过 `static final _dio = ApiClient().dio` 引用同一个
/// Dio 实例。因此只要替换 `ApiClient().dio.httpClientAdapter`，
/// 全部 API 请求都会被传输层拦截，不触达真实网络。
/// ============================================================

/// 传输层 Mock 适配器：按 handler 返回应答。
class MockHttpClientAdapter implements HttpClientAdapter {
  MockHttpClientAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

/// 构造 JSON 应答体（返回 Future，兼容同步箭头函数 `(o) => jsonResponse(...)`）。
Future<ResponseBody> jsonResponse(Object data, {int statusCode = 200}) async {
  return ResponseBody.fromString(
    jsonEncode(data),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

/// 构造纯文本应答体（返回 Future）。
Future<ResponseBody> textResponse(String body, {int statusCode = 200}) async {
  return ResponseBody.fromString(body, statusCode);
}

/// 请求记录器：记录所有经过 adapter 的请求，便于断言路径/参数。
class RequestRecorder {
  final List<RequestOptions> requests = [];

  RequestOptions? last() => requests.isEmpty ? null : requests.last;

  Iterable<RequestOptions> wherePath(String path) =>
      requests.where((r) => r.path.contains(path));
}

/// 安装 mock adapter 并返回记录器。
RequestRecorder installMockAdapter(
  Future<ResponseBody> Function(RequestOptions options) handler, {
  RequestRecorder? recorder,
}) {
  final rec = recorder ?? RequestRecorder();
  final adapter = MockHttpClientAdapter((options) {
    rec.requests.add(options);
    return handler(options);
  });
  ApiClient().dio.httpClientAdapter = adapter;
  return rec;
}

/// 复位单例状态，避免用例间 token/有效 URL 互相污染。
void resetApiClientState() {
  ApiClient().clearToken();
  ApiClient().resetEffectiveBaseUrl();
}

/// 让平台通道在测试环境中不抛异常（ApiClient 构造时会订阅
/// connectivity_plus 事件流）。应在每个测试文件的 main() 最前调用。
void ensureTestBinding() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    const MethodChannel('dev.fluttercommunity.plus/connectivity'),
    (call) async {
      // EventChannel 的 listen/cancel 期望返回 null 表示成功；
      // checkConnectivity 期望返回连接类型列表。
      if (call.method == 'listen' || call.method == 'cancel') return null;
      return ['wifi'];
    },
  );
}
