import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotesController extends StateNotifier<String> {
  NotesController() : super('Physics: F=ma\nCircuits: V=IR\nMath: ax²+bx+c=0') {
    _ready = load();
  }

  static const _key = 'engisteps_notes';
  late final Future<void> _ready;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) state = prefs.getString(_key) ?? state;
  }

  Future<void> save(String value) async {
    await _ready;
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(_key, value)) {
      throw StateError('Could not save notes');
    }
    if (mounted) state = value;
  }
}

final notesProvider = StateNotifierProvider<NotesController, String>((ref) {
  return NotesController();
});
