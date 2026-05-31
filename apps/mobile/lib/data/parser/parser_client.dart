import '../../domain/parse_result.dart';

const parserFailureDisplayMessage = '这次我没能稳定解析成可保存的数据。你可以重试，或者先手动记录。';

abstract interface class ParserClient {
  Future<ParseResult> parseInput(String text);
}

class ParserFailure implements Exception {
  const ParserFailure({required this.code, required this.userMessage});

  final String code;
  final String userMessage;

  @override
  String toString() => userMessage;
}
