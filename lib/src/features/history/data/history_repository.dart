import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryEntry {
  HistoryEntry({
    required this.id,
    required this.toolId,
    required this.timestamp,
    required this.inputs,
    required this.output,
  });

  final String id;
  final String toolId;
  final DateTime timestamp;
  final Map<String, String> inputs;
  final String output;

  Map<String, dynamic> toJson() => {
        'id': id,
        'toolId': toolId,
        'timestamp': timestamp.toIso8601String(),
        'inputs': inputs,
        'output': output,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        id: json['id'] as String,
        toolId: json['toolId'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        inputs: Map<String, String>.from(json['inputs'] as Map),
        output: json['output'] as String,
      );
}

abstract class HistoryRepository {
  Future<List<HistoryEntry>> list();
  Future<void> add(HistoryEntry entry);
  Future<void> clear();
}

class SharedPrefsHistoryRepository implements HistoryRepository {
  static const _key = 'history';
  static const _maxItems = 50;

  @override
  Future<void> add(HistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await list();
    all.insert(0, entry);
    final trimmed = all.take(_maxItems).map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_key, trimmed);
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  @override
  Future<List<HistoryEntry>> list() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key) ?? [];
    return data.map((e) => HistoryEntry.fromJson(jsonDecode(e) as Map<String, dynamic>)).toList();
  }
}

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return SharedPrefsHistoryRepository();
});

final historyProvider = FutureProvider<List<HistoryEntry>>((ref) {
  return ref.watch(historyRepositoryProvider).list();
});
