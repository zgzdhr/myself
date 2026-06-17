import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/domain/extracted_item.dart';
import 'package:mobile/features/extracted_items/task_update_matcher.dart';

void main() {
  const matcher = TaskUpdateMatcher();

  test('matches noisy spoken cancellation to concrete task target', () {
    final result = matcher.match(
      intent: const TaskUpdateIntent(
        action: TaskUpdateAction.cancel,
        targetTaskTitle: '下午开会',
        targetText: '下午开会那个事',
      ),
      sourceText: '呃下午开会那个事先算了吧，今天不开了。',
      activeTaskCandidates: const [
        TaskUpdateCandidate(id: 'task-meeting', title: '下午开会'),
        TaskUpdateCandidate(id: 'task-report', title: '整理客户资料'),
      ],
    );

    expect(result.resolution, TaskUpdateResolution.ready);
    expect(result.candidates.map((candidate) => candidate.id), [
      'task-meeting',
    ]);
  });

  test('requires selection when delay has target but no new time', () {
    final result = matcher.match(
      intent: const TaskUpdateIntent(
        action: TaskUpdateAction.delay,
        targetTaskTitle: '准备方案',
        targetText: '准备方案那个任务',
      ),
      sourceText: '准备方案那个任务先往后放一放。',
      activeTaskCandidates: const [
        TaskUpdateCandidate(id: 'task-plan', title: '准备方案'),
      ],
    );

    expect(result.resolution, TaskUpdateResolution.needsSelection);
    expect(result.candidates.map((candidate) => candidate.id), ['task-plan']);
  });

  test('matches clear delay wording after removing update noise', () {
    final result = matcher.match(
      intent: const TaskUpdateIntent(
        action: TaskUpdateAction.delay,
        targetTaskTitle: '客户资料整理',
        targetText: '客户资料整理这件事',
        dueTimeText: '下周一下午三点',
      ),
      sourceText: '把客户资料整理这件事挪到下周一下午三点。',
      activeTaskCandidates: const [
        TaskUpdateCandidate(id: 'task-customer-docs', title: '客户资料整理'),
      ],
    );

    expect(result.resolution, TaskUpdateResolution.ready);
    expect(result.candidates.map((candidate) => candidate.id), [
      'task-customer-docs',
    ]);
  });
}
