enum TaskStatus {
  active('active'),
  completed('completed'),
  cancelled('cancelled');

  const TaskStatus(this.value);

  final String value;

  static TaskStatus fromValue(String value) {
    return TaskStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => throw FormatException('Unsupported task status: $value'),
    );
  }
}
