import '../../domain/plan_result.dart';

abstract class PlanClient {
  const PlanClient();

  Future<PlanResult> generateDailyPlan(Map<String, Object?> requestJson);
}

class PlanFailure implements Exception {
  const PlanFailure({required this.code, required this.userMessage});

  final String code;
  final String userMessage;

  @override
  String toString() => 'PlanFailure($code): $userMessage';
}
