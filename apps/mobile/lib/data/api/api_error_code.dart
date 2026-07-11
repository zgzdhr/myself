import 'dart:convert';

const unconfiguredApiHost = 'api-not-configured.invalid';

bool isUnconfiguredApiUri(Uri uri) => uri.host == unconfiguredApiHost;

String? apiErrorCodeFromResponseBody(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, Object?>) return null;
    final error = decoded['error'];
    if (error is! Map<String, Object?>) return null;
    final code = error['code'];
    return code is String && code.isNotEmpty ? code : null;
  } on FormatException {
    return null;
  }
}
