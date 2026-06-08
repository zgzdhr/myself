String formatTaskDueText({
  DateTime? dueTime,
  String? dueTimeText,
  DateTime? now,
}) {
  final originalText = dueTimeText?.trim();
  final hasOriginalText = originalText != null && originalText.isNotEmpty;

  if (dueTime == null) {
    return hasOriginalText ? '时间待明确｜原文：$originalText' : '未设时间';
  }

  final localDueTime = dueTime.toLocal();
  final dateText = '${localDueTime.month}月${localDueTime.day}日';
  final timeText =
      '${_twoDigits(localDueTime.hour)}:${_twoDigits(localDueTime.minute)}';
  final concreteText = '$dateText $timeText';

  final overduePrefix = now != null && dueTime.isBefore(now) ? '已逾期｜' : '';
  final displayText = hasOriginalText
      ? '$concreteText｜原文：$originalText'
      : concreteText;
  return '$overduePrefix$displayText';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');
