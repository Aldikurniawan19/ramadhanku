import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/notification_service.dart';
import '../data/services/background_alarm_service.dart';
import '../data/models/prayer_time_model.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final BackgroundAlarmService _backgroundAlarmService = BackgroundAlarmService();

  bool _isAdhanEnabled = true;
  bool _isIftarEnabled = true;
  bool _isImsakEnabled = true;

  bool get isAdhanEnabled => _isAdhanEnabled;
  bool get isIftarEnabled => _isIftarEnabled;
  bool get isImsakEnabled => _isImsakEnabled;

  NotificationProvider() {
    _initAndLoadSettings();
  }

  Future<void> _initAndLoadSettings() async {
    await _notificationService.init();
    await reloadSettings();
  }

  Future<void> reloadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isAdhanEnabled = prefs.getBool('is_adhan_enabled') ?? prefs.getBool('notif_master') ?? true;
    _isIftarEnabled = prefs.getBool('is_iftar_enabled') ?? prefs.getBool('notif_maghrib') ?? true;
    _isImsakEnabled = prefs.getBool('is_imsak_enabled') ?? prefs.getBool('notif_imsak') ?? true;
    notifyListeners();
  }

  Future<void> toggleAdhan(bool value, {PrayerTimesData? currentData}) async {
    _isAdhanEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_adhan_enabled', value);
    if (currentData != null) {
      await schedulePrayerAlerts(currentData);
    }
  }

  Future<void> toggleIftar(bool value, {PrayerTimesData? currentData}) async {
    _isIftarEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_iftar_enabled', value);
    if (currentData != null) {
      await schedulePrayerAlerts(currentData);
    }
  }

  Future<void> toggleImsak(bool value, {PrayerTimesData? currentData}) async {
    _isImsakEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_imsak_enabled', value);
    if (currentData != null) {
      await schedulePrayerAlerts(currentData);
    }
  }

  Future<void> schedulePrayerAlerts(PrayerTimesData data) async {
    try {
      await _notificationService.scheduleAllPrayerTimes(
        data.prayers,
        data.city,
        isAdhanEnabled: _isAdhanEnabled,
        isIftarEnabled: _isIftarEnabled,
        isImsakEnabled: _isImsakEnabled,
      );
    } catch (e) {
      debugPrint('[NotifProvider] Error scheduling prayer times: $e');
    }

    // Also schedule background alarms as backup
    try {
      await _backgroundAlarmService.scheduleAllBackgroundAlarms(
        prayers: BackgroundAlarmService.prayerItemsToMaps(data.prayers),
        cityName: data.city,
        isAdhanEnabled: _isAdhanEnabled,
        isIftarEnabled: _isIftarEnabled,
        isImsakEnabled: _isImsakEnabled,
      );
    } catch (e) {
      debugPrint('[NotifProvider] Error scheduling background alarms: $e');
    }
  }

  Future<bool> requestNotificationPermissions() async {
    return await _notificationService.requestPermissions();
  }

  /// Request all critical permissions at once:
  /// POST_NOTIFICATIONS, EXACT_ALARM, and BATTERY_OPTIMIZATION
  Future<void> checkAndRequestAllPermissions() async {
    await _notificationService.requestPermissions();
    await _notificationService.requestDisableBatteryOptimization();
  }

  /// Request user to disable battery optimization for reliable background alarms
  Future<bool> requestDisableBatteryOptimization() async {
    return await _notificationService.requestDisableBatteryOptimization();
  }

  /// Check if battery optimization is already disabled
  Future<bool> isBatteryOptimizationDisabled() async {
    return await _notificationService.isBatteryOptimizationDisabled();
  }

  Future<void> testInstantNotification() async {
    await _notificationService.showInstantNotification(
      id: 999,
      title: 'Notifikasi Ramadhan Aktif',
      body: 'Pengingat adzan (1 menit sebelum waktu sholat) telah berhasil diaktifkan.',
    );
  }

  Future<void> openNotificationSettings() async {
    await _notificationService.openNotificationSettings();
  }
}
