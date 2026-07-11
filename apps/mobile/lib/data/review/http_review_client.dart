import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../api/api_error_code.dart';
import '../api/api_access_token_provider.dart';
import '../../domain/review_result.dart';
import '../parser/http_parser_client.dart';
import 'review_client.dart';

typedef ReviewHttpPost =
    Future<ParserHttpResponse> Function(
      Uri uri,
      Map<String, String> headers,
      String body,
    );

class HttpReviewClient implements ReviewClient {
  HttpReviewClient({
    required this.baseUri,
    ReviewHttpPost? postJson,
    this.timeout = const Duration(seconds: 18),
    this.accessTokenProvider,
    this.requireAuthentication = false,
  }) : postJson = postJson ?? _defaultPostJson;

  final Uri baseUri;
  final ReviewHttpPost postJson;
  final Duration timeout;
  final ApiAccessTokenProvider? accessTokenProvider;
  final bool requireAuthentication;

  @override
  Future<ReviewResult> generateDailyReview(
    Map<String, Object?> requestJson,
  ) async {
    final response = await _sendReviewRequest(requestJson);

    if (response.statusCode == 401) {
      throw const ReviewFailure(
        code: 'sign_in_required',
        userMessage: '登录状态已失效，请在“我的”里重新完成邮箱登录后再生成复盘。',
      );
    }

    if (response.statusCode == 429) {
      if (apiErrorCodeFromResponseBody(response.body) ==
          'daily_quota_exhausted') {
        throw const ReviewFailure(
          code: 'daily_quota_exhausted',
          userMessage: '今天的 AI 使用次数已达上限，请明天再继续复盘。',
        );
      }
      throw const ReviewFailure(
        code: 'rate_limited',
        userMessage: 'AI 请求太频繁了，请稍等一会儿再试。',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const ReviewFailure(
        code: 'review_service_error',
        userMessage: '复盘服务暂时不可用，请稍后再试。',
      );
    }

    try {
      final json = jsonDecode(response.body) as Map<String, Object?>;
      return ReviewResult.fromJson(json);
    } on FormatException {
      throw const ReviewFailure(
        code: 'invalid_response',
        userMessage: '复盘结果格式异常，请稍后再试。',
      );
    } on TypeError {
      throw const ReviewFailure(
        code: 'invalid_response',
        userMessage: '复盘结果格式异常，请稍后再试。',
      );
    }
  }

  Future<ParserHttpResponse> _sendReviewRequest(
    Map<String, Object?> requestJson,
  ) async {
    try {
      if (isUnconfiguredApiUri(baseUri)) {
        throw const ReviewFailure(
          code: 'api_not_configured',
          userMessage: '此测试包尚未配置安全的 AI 服务地址，请联系测试负责人。',
        );
      }
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (requireAuthentication) {
        final accessToken = await accessTokenProvider?.getAccessToken();
        if (accessToken == null || accessToken.isEmpty) {
          throw const ReviewFailure(
            code: 'sign_in_required',
            userMessage: '生成复盘前，请先在“我的”里完成邮箱登录。',
          );
        }
        headers['Authorization'] = 'Bearer $accessToken';
      }

      return await postJson(
        baseUri.resolve('/review'),
        headers,
        jsonEncode(requestJson),
      ).timeout(timeout);
    } on ReviewFailure {
      rethrow;
    } on TimeoutException {
      throw const ReviewFailure(
        code: 'network_timeout',
        userMessage: '复盘服务响应超时，请稍后再试。',
      );
    } catch (_) {
      throw const ReviewFailure(
        code: 'network_error',
        userMessage: '暂时无法连接复盘服务，请稍后再试。',
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
