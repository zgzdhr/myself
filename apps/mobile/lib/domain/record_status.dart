enum RecordStatus {
  pending,
  confirmed,
  edited,
  rejected,
  deleted,
  expired,
  archived,
}

extension RecordStatusValue on RecordStatus {
  String get value => name;

  static RecordStatus fromValue(String value) {
    return RecordStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => throw FormatException('Unsupported record status: $value'),
    );
  }
}
