import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReviewAffectsHomePreference extends Notifier<bool> {
  @override
  bool build() => true;

  void setEnabled(bool value) {
    state = value;
  }
}

final reviewAffectsHomeProvider =
    NotifierProvider<ReviewAffectsHomePreference, bool>(
      ReviewAffectsHomePreference.new,
    );
