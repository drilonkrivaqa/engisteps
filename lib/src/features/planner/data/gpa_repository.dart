import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CourseGrade {
  const CourseGrade({
    required this.id,
    required this.name,
    required this.credits,
    required this.gradePoint,
  });

  final String id;
  final String name;
  final double credits;
  final double gradePoint;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'credits': credits,
      'gradePoint': gradePoint,
    };
  }

  factory CourseGrade.fromJson(Map<String, dynamic> json) {
    return CourseGrade(
      id: json['id'] as String,
      name: json['name'] as String,
      credits: (json['credits'] as num).toDouble(),
      gradePoint: (json['gradePoint'] as num).toDouble(),
    );
  }
}

class GpaController extends StateNotifier<List<CourseGrade>> {
  GpaController() : super(const <CourseGrade>[]) {
    load();
  }

  static const _key = 'gpa_courses';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? <String>[];
    state = raw
        .map((entry) => CourseGrade.fromJson(jsonDecode(entry) as Map<String, dynamic>))
        .toList();
  }

  Future<void> add({
    required String name,
    required double credits,
    required double gradePoint,
  }) async {
    final next = [
      CourseGrade(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        credits: credits,
        gradePoint: gradePoint,
      ),
      ...state,
    ];

    state = next;
    await _save(next);
  }

  Future<void> remove(String id) async {
    final next = state.where((course) => course.id != id).toList();
    state = next;
    await _save(next);
  }

  Future<void> clear() async {
    state = <CourseGrade>[];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<void> _save(List<CourseGrade> courses) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      courses.map((course) => jsonEncode(course.toJson())).toList(),
    );
  }
}

final gpaProvider = StateNotifierProvider<GpaController, List<CourseGrade>>((ref) {
  return GpaController();
});
