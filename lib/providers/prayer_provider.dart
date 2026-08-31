import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/prayer_time_model.dart';
import '../data/services/prayer_service.dart';
import '../data/services/firebase_service.dart';
import '../data/services/location_service.dart';
import '../data/services/notification_service.dart';
import '../data/services/background_alarm_service.dart';

class PrayerProvider extends ChangeNotifier with WidgetsBindingObserver {
  final PrayerService _prayerService = PrayerService();
  final LocationService _locationService = LocationService();
  final NotificationService _notificationService = NotificationService();
  final BackgroundAlarmService _backgroundAlarmService = BackgroundAlarmService();

  PrayerTimesData? _data;
  bool _isLoading = true;
  String _errorMessage = '';
  String _currentCity = 'Jakarta';
  String _currentCountry = 'Indonesia';
  Timer? _timer;

  PrayerTimesData? get data => _data;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get currentCity => _currentCity;

  PrayerProvider() {
    WidgetsBinding.instance.addObserver(this);
    loadPrayerTimes();
    _startCountdownTimer();
  }

  /// Re-schedule notifications when the app comes back to the foreground.
  /// This is critical for physical devices where the OS may have killed
  /// the scheduled alarms while the app was in the background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('[PrayerProvider] App resumed — re-scheduling notifications');
      if (_data != null && _data!.prayers.isNotEmpty) {
        _notificationService.scheduleAllPrayerTimes(_data!.prayers, _currentCity);
        // Also schedule background alarms as backup
        _backgroundAlarmService.scheduleAllBackgroundAlarms(
          prayers: BackgroundAlarmService.prayerItemsToMaps(_data!.prayers),
          cityName: _currentCity,
        ).catchError((e) {
          debugPrint('[PrayerProvider] Error scheduling background alarms on resume: $e');
        });
      }
      // Also reload prayer times to ensure countdown is accurate
      loadPrayerTimes();
    }
  }

  Future<void> loadPrayerTimes({String? city, String? country}) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    final uid = FirebaseService().currentUser?.uid ?? 'default';
    final prefs = await SharedPreferences.getInstance();

    if (city != null) {
      _currentCity = city;
      await prefs.setString('selected_city_$uid', city);
      await FirebaseService().saveSelectedCity(city, country: country);
    } else {
      final savedCity = prefs.getString('selected_city_$uid');
      if (savedCity != null && savedCity.isNotEmpty) {
        _currentCity = savedCity;
      } else {
        // Fallback to Firebase Cloud Firestore if not found in local prefs
        try {
          final cloudCity = await FirebaseService().getSelectedCity();
          if (cloudCity != null && cloudCity.isNotEmpty) {
            _currentCity = cloudCity;
            await prefs.setString('selected_city_$uid', cloudCity);
          }
        } catch (e) {
          debugPrint('[PrayerProvider] Error loading city from Firestore: $e');
        }
      }
    }

    if (country != null) _currentCountry = country;

    try {
      _data = await _prayerService.fetchPrayerTimes(
        city: _currentCity,
        country: _currentCountry,
      );

      if (_data != null && _data!.prayers.isNotEmpty) {
        debugPrint('[PrayerProvider] Prayer times loaded — scheduling notifications for $_currentCity');
        try {
          await _notificationService.scheduleAllPrayerTimes(_data!.prayers, _currentCity);
        } catch (e) {
          debugPrint('[PrayerProvider] Error scheduling notifications: $e');
        }
        // Schedule background alarms as backup for when app is killed/screen off
        try {
          await _backgroundAlarmService.scheduleAllBackgroundAlarms(
            prayers: BackgroundAlarmService.prayerItemsToMaps(_data!.prayers),
            cityName: _currentCity,
          );
        } catch (e) {
          debugPrint('[PrayerProvider] Error scheduling background alarms: $e');
        }
      }
    } catch (e) {
      _errorMessage = 'Gagal mengambil jadwal sholat: $e';
      debugPrint('[PrayerProvider] Error fetching prayer times: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> detectAndLoadGpsLocation({bool promptEnableGps = true}) async {
    final detectedCity = await _locationService.getCurrentCityName(promptEnableGps: promptEnableGps);
    if (detectedCity != null && detectedCity.isNotEmpty) {
      await loadPrayerTimes(city: detectedCity);
      return detectedCity;
    } else {
      throw 'Tidak dapat menemukan nama wilayah dari koordinat GPS Anda.';
    }
  }

  void _startCountdownTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_data != null) {
        if (_data!.timeRemaining.inSeconds > 0) {
          final newRemaining = _data!.timeRemaining - const Duration(seconds: 1);
          _data = PrayerTimesData(
            prayers: _data!.prayers,
            city: _data!.city,
            dateStr: _data!.dateStr,
            nextPrayerName: _data!.nextPrayerName,
            nextPrayerTime: _data!.nextPrayerTime,
            timeRemaining: newRemaining,
          );
          notifyListeners();

          // 1 minute (60s) remaining alert for foreground
          if (newRemaining.inSeconds == 60) {
            _triggerOneMinuteBeforePrayerNotification();
          } else if (newRemaining.inSeconds == 0) {
            _triggerRealtimePrayerNotification();
          }
        } else if (_data!.timeRemaining.inSeconds <= 0) {
          _triggerRealtimePrayerNotification();
          loadPrayerTimes();
        }
      }
    });
  }

  void _triggerOneMinuteBeforePrayerNotification() {
    if (_data == null) return;
    debugPrint('[PrayerProvider] Foreground trigger: 1 min before ${_data!.nextPrayerName}');
    _notificationService.showInstantNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Waktu Sholat ${_data!.nextPrayerName} 1 Menit Lagi ($_currentCity)',
      body: 'Pengingat: 1 menit lagi memasuki waktu sholat ${_data!.nextPrayerName} untuk wilayah $_currentCity dan sekitarnya.',
    );
  }

  void _triggerRealtimePrayerNotification() {
    if (_data == null) return;
    debugPrint('[PrayerProvider] Foreground trigger: ${_data!.nextPrayerName} time reached');
    _notificationService.showInstantNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Waktu Sholat ${_data!.nextPrayerName} ($_currentCity)',
      body: 'Telah memasuki waktu sholat ${_data!.nextPrayerName} untuk wilayah $_currentCity dan sekitarnya.',
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }
}
