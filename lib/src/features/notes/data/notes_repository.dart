import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotesController extends StateNotifier<String> {
  NotesController()
      : super('Physics: F=ma\nCircuits: V=IR\nMath: ax²+bx+c=0') {
    load();
  }

  static const _key = 'engisteps_notes';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_key) ?? state;
  }

  Future<void> save(String value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, value);
  }
}

final notesProvider = StateNotifierProvider<NotesController, String>((ref) {
  return NotesController();
});
