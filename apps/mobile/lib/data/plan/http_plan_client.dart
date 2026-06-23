import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../domain/plan_result.dart';
import '../parser/http_parser_client.dart';
import 'plan_client.dart';

typedef PlanHttpPost =
    Future<ParserHttpResponse> Function(
      Uri uri,
      Map<String, String> headers,
      String body,
    );

class HttpPlanClient implements PlanClient {
  HttpPlanClient({
    required this.baseUri,
    PlanHttpPost? postJson,
    this.timeout = const Duration(seconds: 20),
  }) : postJson = postJson ?? _defaultPostJson;

  final Uri baseUri;
  final PlanHttpPost postJson;
  final Duration timeout;

  @override
  Future<PlanResult> generateDailyPlan(Map<String, Object?> requestJson) async {
    final response = await _sendPlanRequest(requestJson);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const PlanFailure(
        code: 'plan_service_error',
        userMessage: '时间规划服务暂时不可用，请稍后再试。',
      );
    }

    try {
      final json = jsonDecode(response.body) as Map<String, Object?>;
      return PlanResult.fromJson(json);
    } on FormatException {
      throw const PlanFailure(
        code: 'invalid_response',
        userMessage: '时间规划结果格式异常，请稍后再试。',
      );
    } on TypeError {
      throw const PlanFailure(
        code: 'invalid_response',
        userMessage: '时间规划结果格式异常，请稍后再试。',
      );
    }
  }

  Future<ParserHttpResponse> _sendPlanRequest(
    Map<String, Object?> requestJson,
  ) async {
    try {
      return await postJson(baseUri.resolve('/plan'), {
        'Content-Type': 'application/json',
      }, jsonEncode(requestJson)).timeout(timeout);
    } on PlanFailure {
      rethrow;
    } on TimeoutException {
      throw const PlanFailure(
        code: 'network_timeout',
        userMessage: '时间规划服务响应超时，请稍后再试。',
      );
    } catch (_) {
      throw const PlanFailure(
        code: 'network_error',
        userMessage: '暂时无法连接时间规划服务，请稍后再试。',
      );
    }
  }

  static Future<ParserHttpResponse> _defaultPostJson(
    Uri uri,
    Map<String, String> headers,
    String body,
  ) async {
    final httpClient = HttpClient();

    try {
      final request = await httpClient.postUrl(uri);
      headers.forEach(request.headers.set);
      request.add(utf8.encode(body));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      return ParserHttpResponse(
        statusCode: response.statusCode,
        body: responseBody,
      );
    } finally {
      httpClient.close(force: true);
    }
  }
}
