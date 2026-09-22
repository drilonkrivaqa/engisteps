import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:engisteps/src/features/history/data/history_repository.dart';
import 'package:engisteps/src/features/favorites/data/favorites_repository.dart';

HistoryEntry entry(String id) => HistoryEntry(
  id: id,
  toolId: 'ohms_resistors',
  timestamp: DateTime(2026),
  inputs: {'R1': '2.2', 'R2': '1'},
  output: 'Saved output',
  units: {'R1': 'kΩ'},
  degrees: {'theta': false},
  options: {'mode': 1},
  details: {'Current': '0.1 A'},
  steps: ['A step'],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('Complete calculation round trips through JSON', () {
    final original = entry('1');
    final restored = HistoryEntry.fromJson(
      jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
    );
    expect(restored.toJson(), original.toJson());
  });
  test('Legacy entries remain readable', () {
    final json = entry('1').toJson()
      ..remove('units')
      ..remove('degrees')
      ..remove('options')
      ..remove('details')
      ..remove('version')
      ..remove('steps');
    expect(HistoryEntry.fromJson(json).output, 'Saved output');
    expect(HistoryEntry.fromJson(json).version, 1);
  });
  test('Snapshots cannot be mutated after creation', () {
    final input = {'x': '1'};
    final snapshot = HistoryEntry(
      id: 'immutable',
      toolId: 'sig_figs',
      timestamp: DateTime(2026),
      inputs: input,
      output: '1',
    );
    input['x'] = '9';
    expect(snapshot.inputs['x'], '1');
    expect(() => snapshot.inputs['x'] = '2', throwsUnsupportedError);
  });
  test('Corrupt records do not discard valid history', () async {
    SharedPreferences.setMockInitialValues({
      'history_entries': [
        'bad json',
        jsonEncode(entry('old').toJson()),
        '{"id":3}',
      ],
    });
    final controller = HistoryController();
    addTearDown(controller.dispose);
    await controller.add(entry('new'));
    expect(controller.state.map((e) => e.id), ['new', 'old']);
  });
  test('Rapid writes preserve order and survive reload', () async {
    final controller = HistoryController();
    addTearDown(controller.dispose);
    await Future.wait([
      controller.add(entry('1')),
      controller.add(entry('2')),
      controller.add(entry('3')),
    ]);
    await controller.add(entry('3'));
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs
        .getStringList('history_entries')!
        .map((v) => jsonDecode(v)['id']);
    expect(ids, ['3', '2', '1']);
    await controller.clear();
    expect(prefs.getStringList('history_entries'), isEmpty);
  });
  test('Toggling during initial load preserves saved favorites', () async {
    SharedPreferences.setMockInitialValues({
      'favorites_ordered': ['old'],
    });
    final controller = FavoritesController();
    addTearDown(controller.dispose);
    await controller.toggle('new');
    expect(controller.state, ['new', 'old']);
  });
}
