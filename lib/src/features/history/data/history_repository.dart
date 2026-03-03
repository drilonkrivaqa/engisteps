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

class HistoryController extends StateNotifier<List<HistoryEntry>> {
  HistoryController() : super(const []) {
    load();
  }

  static const _key = 'history_entries';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? <String>[];
    state = raw.map((e) => HistoryEntry.fromJson(jsonDecode(e) as Map<String, dynamic>)).toList();
  }

  Future<void> add(HistoryEntry entry) async {
    final next = [entry, ...state].take(200).toList();
    state = next;
    await _save(next);
  }

  Future<void> clear() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<void> _save(List<HistoryEntry> values) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, values.map((e) => jsonEncode(e.toJson())).toList());
  }
}

final historyProvider = StateNotifierProvider<HistoryController, List<HistoryEntry>>((ref) {
  return HistoryController();
});
