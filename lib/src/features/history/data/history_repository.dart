import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryEntry {
  HistoryEntry({
    required this.id,
    required this.toolId,
    required this.timestamp,
    required Map<String, String> inputs,
    required this.output,
    Map<String, String> units = const {},
    Map<String, bool> degrees = const {},
    Map<String, double> options = const {},
    Map<String, String> details = const {},
    List<String> steps = const [],
    this.version = 2,
  }) : inputs = Map.unmodifiable(inputs),
       units = Map.unmodifiable(units),
       degrees = Map.unmodifiable(degrees),
       options = Map.unmodifiable(options),
       details = Map.unmodifiable(details),
       steps = List.unmodifiable(steps);

  final String id;
  final String toolId;
  final DateTime timestamp;
  final Map<String, String> inputs;
  final String output;
  final Map<String, String> units;
  final Map<String, bool> degrees;
  final Map<String, double> options;
  final Map<String, String> details;
  final List<String> steps;
  final int version;

  Map<String, dynamic> toJson() => {
    'id': id,
    'toolId': toolId,
    'timestamp': timestamp.toIso8601String(),
    'inputs': inputs,
    'output': output,
    'units': units,
    'degrees': degrees,
    'options': options,
    'details': details,
    'steps': steps,
    'version': version,
  };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
    id: json['id'] as String,
    toolId: json['toolId'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    inputs: Map<String, String>.from(json['inputs'] as Map),
    output: json['output'] as String,
    units: Map<String, String>.from(json['units'] as Map? ?? {}),
    degrees: Map<String, bool>.from(json['degrees'] as Map? ?? {}),
    options: (json['options'] as Map? ?? {}).map(
      (k, v) => MapEntry(k as String, (v as num).toDouble()),
    ),
    details: Map<String, String>.from(json['details'] as Map? ?? {}),
    steps: List<String>.from(json['steps'] as List? ?? []),
    version: json['version'] as int? ?? 1,
  );
}

class HistoryController extends StateNotifier<List<HistoryEntry>> {
  HistoryController() : super(const []) {
    _ready = load();
  }

  static const _key = 'history_entries';
  late final Future<void> _ready;
  Future<void> _writes = Future.value();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? <String>[];
    final entries = <HistoryEntry>[];
    for (final value in raw) {
      try {
        entries.add(
          HistoryEntry.fromJson(jsonDecode(value) as Map<String, dynamic>),
        );
      } on FormatException {
        continue;
      } on TypeError {
        continue;
      }
    }
    if (mounted) state = entries;
  }

  Future<void> add(HistoryEntry entry) => _mutate(
    (entries) =>
        [entry, ...entries.where((e) => e.id != entry.id)].take(200).toList(),
  );

  Future<void> clear() => _mutate((_) => []);

  Future<void> remove(String id) =>
      _mutate((entries) => entries.where((entry) => entry.id != id).toList());

  Future<void> _mutate(List<HistoryEntry> Function(List<HistoryEntry>) update) {
    final operation = _writes.then((_) async {
      await _ready;
      final values = update(state);
      await _save(values);
      if (mounted) state = values;
    });
    _writes = operation.catchError((Object _) {});
    return operation;
  }

  Future<void> _save(List<HistoryEntry> values) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setStringList(
      _key,
      values.map((e) => jsonEncode(e.toJson())).toList(),
    )) {
      throw StateError('Could not save history');
    }
  }
}

final historyProvider =
    StateNotifierProvider<HistoryController, List<HistoryEntry>>((ref) {
      return HistoryController();
    });
