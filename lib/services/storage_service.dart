import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gym_set.dart';

class StorageService {
  static const String _historyKey = 'history';
  static const String _customExercisesKey = 'custom_exercises';

  Future<List<GymSet>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_historyKey);
    if (jsonString == null) return [];

    try {
      final decoded = json.decode(jsonString) as List<dynamic>;
      return decoded.map((e) => GymSet.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveHistory(List<GymSet> history) async {
    final prefs = await SharedPreferences.getInstance();
    final data = history.map((s) => s.toJson()).toList();
    final jsonString = json.encode(data);
    await prefs.setString(_historyKey, jsonString);
  }

  Future<List<String>> loadCustomExercises() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_customExercisesKey);
    if (jsonString == null) return [];
    
    try {
      final decoded = json.decode(jsonString) as List<dynamic>;
      return decoded.map((e) => e.toString()).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveCustomExercises(List<String> customExercises) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customExercisesKey, json.encode(customExercises));
  }
}

