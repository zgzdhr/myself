import '../../domain/parse_result.dart';

abstract interface class ParserClient {
  Future<ParseResult> parseInput(String text);
}

class ParserFailure implements Exception {
  const ParserFailure({
    required this.code,
    required this.userMessage,
  });

  final String code;
  final String userMessage;

  @override
  String toString() => userMessage;
}
