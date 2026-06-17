class InferredTaskDue {
  const InferredTaskDue({this.dueTimeText, this.dueTime});

  final String? dueTimeText;
  final DateTime? dueTime;
}

InferredTaskDue inferTaskDue({required String text, required DateTime now}) {
  DateTime atTime(int dayOffset, int hour, [int minute = 0]) {
    return DateTime(now.year, now.month, now.day + dayOffset, hour, minute);
  }

  final explicitClockTime = _firstExplicitClockTime(text);
  DateTime? dueTimeFor(int dayOffset, int defaultHour) {
    if (explicitClockTime == null) {
      return atTime(dayOffset, defaultHour);
    }
    if (!_isReliableClockTime(explicitClockTime)) {
      return null;
    }
    return atTime(
      dayOffset,
      _resolveClockHour(hour: explicitClockTime.hour, text: text),
      explicitClockTime.minute,
    );
  }

  String timeTextFor(String fallbackText) {
    return explicitClockTime?.text ?? fallbackText;
  }

  if (text.contains('大后天')) {
    return InferredTaskDue(
      dueTimeText: timeTextFor('大后天'),
      dueTime: dueTimeFor(3, 9),
    );
  }

  if (text.contains('后天')) {
    return InferredTaskDue(
      dueTimeText: timeTextFor('后天'),
      dueTime: dueTimeFor(2, 9),
    );
  }

  final nextWeekdayOffset = _nextWeekdayOffset(text, now);
  if (nextWeekdayOffset != null) {
    return InferredTaskDue(
      dueTimeText: timeTextFor(_firstNextWeekdayText(text) ?? '下周'),
      dueTime: dueTimeFor(nextWeekdayOffset, 9),
    );
  }

  if (text.contains('明天上午')) {
    return InferredTaskDue(
      dueTimeText: timeTextFor('明天上午'),
      dueTime: dueTimeFor(1, 9),
    );
  }

  if (text.contains('明天下午')) {
    return InferredTaskDue(
      dueTimeText: timeTextFor('明天下午'),
      dueTime: dueTimeFor(1, 14),
    );
  }

  if (text.contains('明天晚上') || text.contains('明晚') || text.contains('明天傍晚')) {
    return InferredTaskDue(
      dueTimeText: timeTextFor(text.contains('明天傍晚') ? '明天傍晚' : '明天晚上'),
      dueTime: dueTimeFor(1, 18),
    );
  }

  if (text.contains('明天')) {
    return InferredTaskDue(
      dueTimeText: timeTextFor('明天'),
      dueTime: dueTimeFor(1, 9),
    );
  }

  if (_hasExplicitDateOutsideTodayOrTomorrow(text)) {
    return InferredTaskDue(dueTimeText: _firstRecognizedTimeText(text));
  }

  if (text.contains('今天上午') || text.contains('上午')) {
    return InferredTaskDue(
      dueTimeText: timeTextFor(text.contains('今天上午') ? '今天上午' : '上午'),
      dueTime: dueTimeFor(0, 9),
    );
  }

  if (text.contains('今天中午') || text.contains('中午')) {
    return InferredTaskDue(
      dueTimeText: timeTextFor(text.contains('今天中午') ? '今天中午' : '中午'),
      dueTime: dueTimeFor(0, 11),
    );
  }

  if (text.contains('今天下午') || text.contains('今下午') || text.contains('下午')) {
    return InferredTaskDue(
      dueTimeText: timeTextFor(
        text.contains('今天下午') || text.contains('今下午') ? '今天下午' : '下午',
      ),
      dueTime: dueTimeFor(0, 14),
    );
  }

  if (text.contains('今天晚上') ||
      text.contains('今晚上') ||
      text.contains('今晚') ||
      text.contains('晚上') ||
      text.contains('傍晚')) {
    return InferredTaskDue(
      dueTimeText: timeTextFor(
        text.contains('今天晚上') || text.contains('今晚上') || text.contains('今晚')
            ? '今晚'
            : text.contains('傍晚')
            ? '傍晚'
            : '晚上',
      ),
      dueTime: dueTimeFor(0, 18),
    );
  }

  if (text.contains('今天')) {
    return InferredTaskDue(
      dueTimeText: timeTextFor('今天'),
      dueTime: dueTimeFor(0, now.hour),
    );
  }

  if (explicitClockTime != null && _isReliableClockTime(explicitClockTime)) {
    return InferredTaskDue(
      dueTimeText: explicitClockTime.text,
      dueTime: dueTimeFor(0, now.hour),
    );
  }

  return const InferredTaskDue();
}

bool _hasExplicitDateOutsideTodayOrTomorrow(String text) {
  return RegExp(r'(周|星期|礼拜)[一二三四五六日天]').hasMatch(text) ||
      RegExp(r'\d{1,2}[月/-]\d{1,2}[日号]?').hasMatch(text) ||
      RegExp(r'(下周|下星期|下礼拜)').hasMatch(text);
}

String? _firstRecognizedTimeText(String text) {
  const timeTexts = [
    '上午',
    '中午',
    '下午',
    '傍晚',
    '晚上',
    '今晚',
    '今晚上',
    '今天上午',
    '今天中午',
    '今天下午',
    '今天晚上',
    '明天上午',
    '明天下午',
    '明天晚上',
    '明天傍晚',
  ];
  for (final timeText in timeTexts) {
    if (text.contains(timeText)) return timeText;
  }
  return null;
}

({String text, int hour, int minute, bool hasDayPeriodContext})?
_firstExplicitClockTime(String text) {
  final numericColonMatch = RegExp(r'(\d{1,2})[:：](\d{1,2})').firstMatch(text);
  if (numericColonMatch != null) {
    final hour = int.parse(numericColonMatch.group(1)!);
    return (
      text: numericColonMatch.group(0)!,
      hour: hour,
      minute: int.parse(numericColonMatch.group(2)!),
      hasDayPeriodContext: _hasDayPeriodContext(text) || hour > 12,
    );
  }

  final numericPointMatch = RegExp(
    r'(\d{1,2})点(半|(\d{1,2})分?)?',
  ).firstMatch(text);
  if (numericPointMatch != null) {
    final halfText = numericPointMatch.group(2);
    final minuteText = numericPointMatch.group(3);
    final hour = int.parse(numericPointMatch.group(1)!);
    return (
      text: numericPointMatch.group(0)!,
      hour: hour,
      minute: halfText == '半' ? 30 : int.tryParse(minuteText ?? '') ?? 0,
      hasDayPeriodContext: _hasDayPeriodContext(text) || hour > 12,
    );
  }

  final chinesePointMatch = RegExp(
    r'([一二两三四五六七八九十]{1,3})点(半)?',
  ).firstMatch(text);
  if (chinesePointMatch != null) {
    final hour = _parseChineseHour(chinesePointMatch.group(1)!);
    if (hour != null) {
      return (
        text: chinesePointMatch.group(0)!,
        hour: hour,
        minute: chinesePointMatch.group(2) == '半' ? 30 : 0,
        hasDayPeriodContext: _hasDayPeriodContext(text),
      );
    }
  }

  return null;
}

bool _isReliableClockTime(
  ({String text, int hour, int minute, bool hasDayPeriodContext}) clockTime,
) {
  return clockTime.hasDayPeriodContext || clockTime.hour > 12;
}

bool _hasDayPeriodContext(String text) {
  return text.contains('上午') ||
      text.contains('中午') ||
      text.contains('下午') ||
      text.contains('晚上') ||
      text.contains('今晚') ||
      text.contains('今晚上') ||
      text.contains('傍晚') ||
      text.contains('明早') ||
      text.contains('明晚');
}

int _resolveClockHour({required int hour, required String text}) {
  if (hour == 12) return hour;
  if (text.contains('下午') ||
      text.contains('晚上') ||
      text.contains('今晚') ||
      text.contains('今晚上') ||
      text.contains('傍晚') ||
      text.contains('明晚')) {
    return hour < 12 ? hour + 12 : hour;
  }
  return hour;
}

int? _parseChineseHour(String text) {
  const digits = {
    '一': 1,
    '二': 2,
    '两': 2,
    '三': 3,
    '四': 4,
    '五': 5,
    '六': 6,
    '七': 7,
    '八': 8,
    '九': 9,
  };
  if (text == '十') return 10;
  if (text.startsWith('十')) {
    return 10 + (digits[text.substring(1)] ?? 0);
  }
  if (text.endsWith('十')) {
    return (digits[text.substring(0, 1)] ?? 0) * 10;
  }
  if (text.contains('十')) {
    final parts = text.split('十');
    return (digits[parts[0]] ?? 0) * 10 + (digits[parts[1]] ?? 0);
  }
  return digits[text];
}

int? _nextWeekdayOffset(String text, DateTime now) {
  final match = RegExp(r'下(周|星期|礼拜)([一二三四五六日天])').firstMatch(text);
  if (match == null) {
    return null;
  }

  final targetWeekday = _parseChineseWeekday(match.group(2)!);
  if (targetWeekday == null) {
    return null;
  }

  final daysUntilNextMonday = DateTime.daysPerWeek - now.weekday + 1;
  return daysUntilNextMonday + targetWeekday - 1;
}

String? _firstNextWeekdayText(String text) {
  return RegExp(r'下(周|星期|礼拜)[一二三四五六日天]').firstMatch(text)?.group(0);
}

int? _parseChineseWeekday(String text) {
  return switch (text) {
    '一' => DateTime.monday,
    '二' => DateTime.tuesday,
    '三' => DateTime.wednesday,
    '四' => DateTime.thursday,
    '五' => DateTime.friday,
    '六' => DateTime.saturday,
    '日' || '天' => DateTime.sunday,
    _ => null,
  };
}
