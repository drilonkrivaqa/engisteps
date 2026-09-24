import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/circuit_course.dart';

class LearningAttempt {
  const LearningAttempt({
    this.methodDone = false,
    this.helped = false,
    this.completed = false,
    this.independent = false,
    this.hintShown = false,
  });
  final bool methodDone, helped, completed, independent, hintShown;
  LearningAttempt copyWith({
    bool? methodDone,
    bool? helped,
    bool? completed,
    bool? independent,
    bool? hintShown,
  }) => LearningAttempt(
    methodDone: methodDone ?? this.methodDone,
    helped: helped ?? this.helped,
    completed: completed ?? this.completed,
    independent: independent ?? this.independent,
    hintShown: hintShown ?? this.hintShown,
  );
  Map<String, dynamic> toJson() => {
    'method': methodDone,
    'helped': helped,
    'completed': completed,
    'independent': independent,
    'hint': hintShown,
  };
  factory LearningAttempt.fromJson(Map<String, dynamic> json) {
    final helped = json['helped'] == true;
    final completed = json['completed'] == true;
    return LearningAttempt(
      methodDone: json['method'] == true,
      helped: helped,
      completed: completed,
      independent: completed && !helped && json['independent'] == true,
      hintShown: json['hint'] == true,
    );
  }
}

class LearningProgress {
  LearningProgress({
    Map<String, LearningAttempt> attempts = const {},
    this.topic = 'series',
  }) : attempts = Map.unmodifiable(attempts);
  final Map<String, LearningAttempt> attempts;
  final String topic;
  LearningAttempt attempt(String id) => attempts[id] ?? const LearningAttempt();
  int get independentCount => circuitProblems
      .where((p) => !p.guided && attempt(p.id).independent)
      .length;
  List<CircuitProblem> get review => circuitProblems
      .where(
        (p) =>
            !p.guided && attempt(p.id).completed && !attempt(p.id).independent,
      )
      .toList();
  CircuitProblem? get next {
    final ordered = [
      ...circuitProblems.where((p) => p.topicId == topic),
      ...circuitProblems.where((p) => p.topicId != topic),
    ];
    for (final p in ordered) {
      if (!attempt(p.id).completed) return p;
    }
    return review.isEmpty ? null : review.first;
  }
}

final learningProvider =
    AsyncNotifierProvider<LearningController, LearningProgress>(
      LearningController.new,
    );

class LearningController extends AsyncNotifier<LearningProgress> {
  static const storageKey = 'learning_progress_v1';
  Future<void> _writes = Future.value();
  @override
  Future<LearningProgress> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null) return LearningProgress();
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final entries = <String, LearningAttempt>{};
      final saved = json['attempts'] as Map<String, dynamic>? ?? {};
      for (final entry in saved.entries) {
        if (findProblem(entry.key) == null ||
            entry.value is! Map<String, dynamic>) {
          continue;
        }
        entries[entry.key] = LearningAttempt.fromJson(
          entry.value as Map<String, dynamic>,
        );
      }
      final topic = json['topic'];
      return LearningProgress(
        attempts: entries,
        topic: circuitTopics.any((t) => t.id == topic)
            ? topic as String
            : 'series',
      );
    } on FormatException {
      return LearningProgress();
    } on TypeError {
      return LearningProgress();
    }
  }

  Future<void> _change(LearningProgress Function(LearningProgress) transform) {
    final operation = _writes.then((_) async {
      final current = await future;
      final updated = transform(current);
      final prefs = await SharedPreferences.getInstance();
      final saved = await prefs.setString(
        storageKey,
        jsonEncode({
          'topic': updated.topic,
          'attempts': updated.attempts.map(
            (key, value) => MapEntry(key, value.toJson()),
          ),
        }),
      );
      if (!saved) throw StateError('Could not save learning progress.');
      state = AsyncData(updated);
    });
    _writes = operation.catchError((Object _) {});
    return operation;
  }

  Future<void> save(String id, LearningAttempt attempt) => _change(
    (p) => LearningProgress(
      topic: findProblem(id)?.topicId ?? p.topic,
      attempts: {...p.attempts, id: attempt},
    ),
  );
}
