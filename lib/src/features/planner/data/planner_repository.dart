import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PlannerPriority {
  low,
  medium,
  high,
}

extension PlannerPriorityLabel on PlannerPriority {
  String get label {
    switch (this) {
      case PlannerPriority.low:
        return 'Low';
      case PlannerPriority.medium:
        return 'Medium';
      case PlannerPriority.high:
        return 'High';
    }
  }
}

class PlannerTask {
  const PlannerTask({
    required this.id,
    required this.title,
    required this.course,
    required this.dueDate,
    required this.priority,
    this.done = false,
  });

  final String id;
  final String title;
  final String course;
  final DateTime dueDate;
  final PlannerPriority priority;
  final bool done;

  PlannerTask copyWith({
    String? id,
    String? title,
    String? course,
    DateTime? dueDate,
    PlannerPriority? priority,
    bool? done,
  }) {
    return PlannerTask(
      id: id ?? this.id,
      title: title ?? this.title,
      course: course ?? this.course,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      done: done ?? this.done,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'course': course,
      'dueDate': dueDate.toIso8601String(),
      'priority': priority.name,
      'done': done,
    };
  }

  factory PlannerTask.fromJson(Map<String, dynamic> json) {
    return PlannerTask(
      id: json['id'] as String,
      title: json['title'] as String,
      course: json['course'] as String? ?? '',
      dueDate: DateTime.parse(json['dueDate'] as String),
      priority: PlannerPriority.values.byName(json['priority'] as String),
      done: json['done'] as bool? ?? false,
    );
  }
}

class PlannerController extends StateNotifier<List<PlannerTask>> {
  PlannerController() : super(const <PlannerTask>[]) {
    load();
  }

  static const _key = 'planner_tasks';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? <String>[];
    final tasks = raw
        .map((entry) => PlannerTask.fromJson(jsonDecode(entry) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    state = tasks;
  }

  Future<void> add({
    required String title,
    required String course,
    required DateTime dueDate,
    required PlannerPriority priority,
  }) async {
    final task = PlannerTask(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      course: course,
      dueDate: DateTime(dueDate.year, dueDate.month, dueDate.day),
      priority: priority,
    );

    final next = <PlannerTask>[task, ...state]..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    state = next;
    await _save(next);
  }

  Future<void> toggle(String id) async {
    final next = state
        .map((task) => task.id == id ? task.copyWith(done: !task.done) : task)
        .toList();
    state = next;
    await _save(next);
  }

  Future<void> remove(String id) async {
    final next = state.where((task) => task.id != id).toList();
    state = next;
    await _save(next);
  }

  Future<void> clearCompleted() async {
    final next = state.where((task) => !task.done).toList();
    state = next;
    await _save(next);
  }

  Future<void> _save(List<PlannerTask> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      tasks.map((task) => jsonEncode(task.toJson())).toList(),
    );
  }
}

final plannerProvider =
    StateNotifierProvider<PlannerController, List<PlannerTask>>((ref) {
  return PlannerController();
});
