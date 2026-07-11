import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../api/api_error_code.dart';
import '../api/api_access_token_provider.dart';
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
    this.accessTokenProvider,
    this.requireAuthentication = false,
  }) : postJson = postJson ?? _defaultPostJson;

  final Uri baseUri;
  final PlanHttpPost postJson;
  final Duration timeout;
  final ApiAccessTokenProvider? accessTokenProvider;
  final bool requireAuthentication;

  @override
  Future<PlanResult> generateDailyPlan(Map<String, Object?> requestJson) async {
    final response = await _sendPlanRequest(requestJson);

    if (response.statusCode == 401) {
      throw const PlanFailure(
        code: 'sign_in_required',
        userMessage: '登录状态已失效，请在“我的”里重新完成邮箱登录后再生成时间规划。',
      );
    }

    if (response.statusCode == 429) {
      if (apiErrorCodeFromResponseBody(response.body) ==
          'daily_quota_exhausted') {
        throw const PlanFailure(
          code: 'daily_quota_exhausted',
          userMessage: '今天的 AI 使用次数已达上限，请明天再继续规划。',
        );
      }
      throw const PlanFailure(
        code: 'rate_limited',
        userMessage: 'AI 请求太频繁了，请稍等一会儿再试。',
      );
    }

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
      if (isUnconfiguredApiUri(baseUri)) {
        throw const PlanFailure(
          code: 'api_not_configured',
          userMessage: '此测试包尚未配置安全的 AI 服务地址，请联系测试负责人。',
        );
      }
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (requireAuthentication) {
        final accessToken = await accessTokenProvider?.getAccessToken();
        if (accessToken == null || accessToken.isEmpty) {
          throw const PlanFailure(
            code: 'sign_in_required',
            userMessage: '生成时间规划前，请先在“我的”里完成邮箱登录。',
          );
        }
        headers['Authorization'] = 'Bearer $accessToken';
      }

      return await postJson(
        baseUri.resolve('/plan'),
        headers,
        jsonEncode(requestJson),
      ).timeout(timeout);
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
