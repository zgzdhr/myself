import '../../domain/review_result.dart';

abstract class ReviewClient {
  const ReviewClient();

  Future<ReviewResult> generateDailyReview(Map<String, Object?> requestJson);
}

class ReviewFailure implements Exception {
  const ReviewFailure({required this.code, required this.userMessage});

  final String code;
  final String userMessage;

  @override
  String toString() => 'ReviewFailure($code): $userMessage';
}
