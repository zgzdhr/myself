import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
  }) : postJson = postJson ?? _defaultPostJson;

  final Uri baseUri;
  final ReviewHttpPost postJson;
  final Duration timeout;

  @override
  Future<ReviewResult> generateDailyReview(
    Map<String, Object?> requestJson,
  ) async {
    final response = await _sendReviewRequest(requestJson);

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
      return await postJson(baseUri.resolve('/review'), {
        'Content-Type': 'application/json',
      }, jsonEncode(requestJson)).timeout(timeout);
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
