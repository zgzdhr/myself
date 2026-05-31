enum ItemType {
  taskCreate,
  taskUpdate,
  shortTermState,
  lifeEvent,
  generalAnswer,
  profileCandidate,
}

extension ItemTypeApiValue on ItemType {
  String get apiValue {
    return switch (this) {
      ItemType.taskCreate => 'task_create',
      ItemType.taskUpdate => 'task_update',
      ItemType.shortTermState => 'short_term_state',
      ItemType.lifeEvent => 'life_event',
      ItemType.generalAnswer => 'general_answer',
      ItemType.profileCandidate => 'profile_candidate',
    };
  }

  static ItemType fromApiValue(String value) {
    return switch (value) {
      'task_create' => ItemType.taskCreate,
      'task_update' => ItemType.taskUpdate,
      'short_term_state' => ItemType.shortTermState,
      'life_event' => ItemType.lifeEvent,
      'general_answer' => ItemType.generalAnswer,
      'profile_candidate' => ItemType.profileCandidate,
      _ => throw FormatException('Unsupported item type: $value'),
    };
  }
}
