import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/fasting_log_model.dart';
import '../data/services/firebase_service.dart';

class FastingProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final Map<String, FastingLogModel> _logs = {};

  Map<String, FastingLogModel> get logs => _logs;
  int get completedDays => _logs.values.where((l) => l.isCompleted).length;

  FastingProvider() {
    reloadUserData();
  }

  Future<void> reloadUserData() async {
    final uid = await _firebaseService.getEffectiveUserId();
    final prefs = await SharedPreferences.getInstance();
    final completedList = prefs.getStringList('fasting_completed_$uid') ?? [];
    _logs.clear();
    for (final dateStr in completedList) {
      _logs[dateStr] = FastingLogModel(date: dateStr, isCompleted: true);
    }
    notifyListeners();
  }

  void toggleFastingDay(String dateStr) async {
    final current = _logs[dateStr];
    final isDone = !(current?.isCompleted ?? false);

    _logs[dateStr] = FastingLogModel(date: dateStr, isCompleted: isDone);
    notifyListeners();

    final uid = await _firebaseService.getEffectiveUserId();
    final prefs = await SharedPreferences.getInstance();
    final completedList = _logs.entries
        .where((e) => e.value.isCompleted)
        .map((e) => e.key)
        .toList();
    await prefs.setStringList('fasting_completed_$uid', completedList);

    _firebaseService.saveFastingLog(dateStr, isDone, '');
  }

  bool isFastingCompleted(String dateStr) {
    return _logs[dateStr]?.isCompleted ?? false;
  }
}
