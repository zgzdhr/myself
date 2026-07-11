import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../api/api_error_code.dart';
import '../api/api_access_token_provider.dart';
import '../../domain/parse_result.dart';
import 'parser_client.dart';

typedef ParserHttpPost =
    Future<ParserHttpResponse> Function(
      Uri uri,
      Map<String, String> headers,
      String body,
    );

class ParserHttpResponse {
  const ParserHttpResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}

class ParserLocationContext {
  const ParserLocationContext({
    this.label,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
  });

  final String? label;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;

  Map<String, Object?> toJson() {
    return {
      if (label != null && label!.trim().isNotEmpty) 'label': label!.trim(),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (accuracyMeters != null) 'accuracy_meters': accuracyMeters,
    };
  }
}

class HttpParserClient implements ParserClient {
  HttpParserClient({
    required this.baseUri,
    this.timezone = 'Asia/Shanghai',
    DateTime Function()? parsedAtProvider,
    ParserLocationContext? Function()? locationContextProvider,
    ParserHttpPost? postJson,
    this.timeout = const Duration(seconds: 12),
    this.accessTokenProvider,
    this.requireAuthentication = false,
  }) : parsedAtProvider = parsedAtProvider ?? DateTime.now,
       locationContextProvider = locationContextProvider ?? (() => null),
       postJson = postJson ?? _defaultPostJson;

  final Uri baseUri;
  final String timezone;
  final DateTime Function() parsedAtProvider;
  final ParserLocationContext? Function() locationContextProvider;
  final ParserHttpPost postJson;
  final Duration timeout;
  final ApiAccessTokenProvider? accessTokenProvider;
  final bool requireAuthentication;

  @override
  Future<ParseResult> parseInput(String text) async {
    final response = await _sendParseRequest(text);

    if (response.statusCode == 401) {
      throw const ParserFailure(
        code: 'sign_in_required',
        userMessage: '登录状态已失效，请在“我的”里重新完成邮箱登录后再使用 AI 整理。',
      );
    }

    if (response.statusCode == 429) {
      if (apiErrorCodeFromResponseBody(response.body) ==
          'daily_quota_exhausted') {
        throw const ParserFailure(
          code: 'daily_quota_exhausted',
          userMessage: '今天的 AI 使用次数已达上限，请明天再继续整理。',
        );
      }
      throw const ParserFailure(
        code: 'rate_limited',
        userMessage: 'AI 请求太频繁了，请稍等一会儿再试。',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const ParserFailure(
        code: 'parser_service_error',
        userMessage: '解析服务暂时不可用，请稍后再试。',
      );
    }

    try {
      final json = jsonDecode(response.body) as Map<String, Object?>;
      return ParseResult.fromAiJson(json: json, parsedAt: parsedAtProvider());
    } on FormatException {
      throw const ParserFailure(
        code: 'invalid_response',
        userMessage: '解析结果格式异常，请稍后再试。',
      );
    } on TypeError {
      throw const ParserFailure(
        code: 'invalid_response',
        userMessage: '解析结果格式异常，请稍后再试。',
      );
    }
  }

  Future<ParserHttpResponse> _sendParseRequest(String text) async {
    final locationContext = locationContextProvider()?.toJson();
    try {
      if (isUnconfiguredApiUri(baseUri)) {
        throw const ParserFailure(
          code: 'api_not_configured',
          userMessage: '此测试包尚未配置安全的 AI 服务地址，请联系测试负责人。',
        );
      }
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (requireAuthentication) {
        final accessToken = await accessTokenProvider?.getAccessToken();
        if (accessToken == null || accessToken.isEmpty) {
          throw const ParserFailure(
            code: 'sign_in_required',
            userMessage: '使用 AI 整理前，请先在“我的”里完成邮箱登录。',
          );
        }
        headers['Authorization'] = 'Bearer $accessToken';
      }

      return await postJson(
        baseUri.resolve('/parse'),
        headers,
        jsonEncode({
          'text': text,
          'timezone': timezone,
          'current_time_iso': parsedAtProvider().toIso8601String(),
          'input_style': 'natural_language',
          if (locationContext != null && locationContext.isNotEmpty)
            'location_context': locationContext,
        }),
      ).timeout(timeout);
    } on ParserFailure {
      rethrow;
    } on TimeoutException {
      throw const ParserFailure(
        code: 'network_timeout',
        userMessage: '解析服务响应超时，请稍后再试。',
      );
    } catch (_) {
      throw const ParserFailure(
        code: 'network_error',
        userMessage: '暂时无法连接解析服务，请稍后再试。',
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
