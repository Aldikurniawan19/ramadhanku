import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/prayer_time_model.dart';

@pragma('vm:entry-point')
Future<void> notificationTapBackground(NotificationResponse notificationResponse) async {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Stop adhan sound when user taps/dismisses notification
  try {
    const platform = MethodChannel('com.ramadhan.app/adhan');
    await platform.invokeMethod('stopAdhan');
  } catch (e) {
    debugPrint('[NotifService] stopAdhan from background tap failed: $e');
  }

  if (notificationResponse.id != null) {
    await notificationsPlugin.cancel(notificationResponse.id!);
  }
  await notificationsPlugin.cancelAll();
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// MethodChannel to communicate with native AdhanPlayerService
  static const MethodChannel _adhanChannel =
      MethodChannel('com.ramadhan.app/adhan');

  bool _isInitialized = false;

  /// =====================================================================
  /// Channel ID v7: Notification channel WITH adzan sound.
  ///
  /// Strategy:
  ///   - Notification channel plays adzan sound (reliable, works in all states)
  ///   - AdhanPlayerService (foreground service) plays full-length adzan
  ///     via native MediaPlayer with USAGE_ALARM (for foreground + some bg)
  ///   - Both layers complement each other for maximum reliability
  ///
  /// Why new channel ID?
  ///   Android caches channel settings immutably after first creation.
  ///   Changing sound/importance requires a new channel ID.
  /// =====================================================================
  static const String _prayerChannelId = 'prayer_adhan_alarm_v7';
  static const String _prayerChannelName = 'Adzan & Waktu Sholat';
  static const String _prayerChannelDesc =
      'Pengingat otomatis adzan ketika memasuki waktu sholat & buka puasa';
  static const String _testChannelId = 'prayer_test_alarm_v7';

  Future<void> init() async {
    if (_isInitialized) return;

    // Initialize Timezone Database
    tz.initializeTimeZones();
    
    try {
      final deviceTimezoneInfo = await FlutterTimezone.getLocalTimezone();
      final String deviceTimezone = deviceTimezoneInfo.identifier;
      debugPrint('[NotifService] Device timezone detected: $deviceTimezone');
      tz.setLocalLocation(tz.getLocation(deviceTimezone));
    } catch (e) {
      debugPrint('[NotifService] FlutterTimezone detection failed: $e — falling back');
      try {
        final String timeZoneName = tz.local.name;
        if (timeZoneName == 'UTC' || timeZoneName == 'GMT' || timeZoneName.isEmpty) {
          tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
        }
      } catch (e2) {
        try {
          tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
        } catch (_) {}
      }
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        debugPrint('[NotifService] Notification tapped: id=${response.id}');
        // Stop adhan sound when user interacts with notification
        await stopAdhanSound();
        if (response.id != null) {
          await _notificationsPlugin.cancel(response.id!);
        }
        await _notificationsPlugin.cancelAll();
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      // =====================================================================
      // Clean up ALL old channel versions so Android doesn't reuse
      // cached channels with wrong importance/audio/category settings.
      // =====================================================================
      final oldChannels = [
        'prayer_adhan_channel_v10',
        'prayer_test_channel_v2',
        'prayer_adhan_fullscreen_v1',
        'prayer_test_fullscreen_v1',
        'prayer_adhan_alert_v2',
        'prayer_test_alert_v2',
        'prayer_adhan_alert_v3',
        'prayer_test_alert_v3',
        'prayer_adhan_alert_v4',
        'prayer_test_alert_v4',
        'prayer_adhan_alarm_v5',
        'prayer_test_alarm_v5',
        'prayer_adhan_alarm_v6',
        'prayer_test_alarm_v6',
      ];
      for (final ch in oldChannels) {
        try {
          await androidPlugin.deleteNotificationChannel(ch);
        } catch (_) {}
      }

      // =====================================================================
      // v7 Channels: WITH adzan sound from notification channel.
      //
      // - Importance.max → heads-up banner display
      // - playSound + adzan.mp3 → reliable fallback for background/screen-off
      // - AdhanPlayerService also plays full-length via native MediaPlayer
      // - Vibration + lights → tactile + visual feedback
      // =====================================================================
      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        _prayerChannelId,
        _prayerChannelName,
        description: _prayerChannelDesc,
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('adzan'),
        enableVibration: true,
        enableLights: true,
      ));

      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        _testChannelId,
        'Uji Coba Notifikasi',
        description: 'Channel uji coba pengingat instan',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('adzan'),
        enableVibration: true,
        enableLights: true,
      ));

      try {
        final notifGranted = await androidPlugin.requestNotificationsPermission();
        debugPrint('[NotifService] POST_NOTIFICATIONS permission: $notifGranted');
      } catch (e) {
        debugPrint('[NotifService] requestNotificationsPermission error: $e');
      }
      try {
        final alarmGranted = await androidPlugin.requestExactAlarmsPermission();
        debugPrint('[NotifService] EXACT_ALARM permission: $alarmGranted');
      } catch (e) {
        debugPrint('[NotifService] requestExactAlarmsPermission error: $e');
      }
    }

    _isInitialized = true;
    debugPrint('[NotifService] Initialized successfully');
  }

  Future<bool> requestPermissions() async {
    await init();
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final notificationGranted = await androidPlugin.requestNotificationsPermission() ?? false;
      final exactAlarmGranted = await androidPlugin.requestExactAlarmsPermission() ?? false;
      debugPrint('[NotifService] Permissions — notif: $notificationGranted, exactAlarm: $exactAlarmGranted');
      return notificationGranted && exactAlarmGranted;
    }
    return true;
  }

  /// =====================================================================
  /// Request user to disable battery optimization for this app.
  /// On physical devices (Samsung, Xiaomi, Oppo, etc.), aggressive battery
  /// optimization kills background processes and prevents scheduled alarms
  /// from firing. This opens the system dialog to whitelist this app.
  /// =====================================================================
  Future<bool> requestDisableBatteryOptimization() async {
    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      debugPrint('[NotifService] Battery optimization status: $status');
      if (status.isGranted) {
        debugPrint('[NotifService] Battery optimization already disabled');
        return true;
      }
      final result = await Permission.ignoreBatteryOptimizations.request();
      debugPrint('[NotifService] Battery optimization request result: $result');
      return result.isGranted;
    } catch (e) {
      debugPrint('[NotifService] Battery optimization request error: $e');
      return false;
    }
  }

  /// Check if battery optimization is already disabled
  Future<bool> isBatteryOptimizationDisabled() async {
    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  Future<void> openNotificationSettings() async {
    await openAppSettings();
  }

  /// Debug helper: print all currently pending notifications
  Future<void> debugPendingNotifications() async {
    try {
      final pending = await _notificationsPlugin.pendingNotificationRequests();
      debugPrint('[NotifService] === Pending Notifications (${pending.length}) ===');
      for (final p in pending) {
        debugPrint('[NotifService]   id=${p.id}, title=${p.title}, body=${p.body}');
      }
      debugPrint('[NotifService] === End Pending Notifications ===');
    } catch (e) {
      debugPrint('[NotifService] Error listing pending notifications: $e');
    }
  }

  /// =====================================================================
  /// Play adhan sound via native Android MediaPlayer (AdhanPlayerService).
  /// This bypasses notification channel sound limitations:
  ///   - Plays full-length audio (30s) instead of truncated ~5s
  ///   - Uses USAGE_ALARM to bypass DND/silent mode
  ///   - Works even when screen is off or app is in background
  /// =====================================================================
  Future<void> playAdhanSound() async {
    try {
      await _adhanChannel.invokeMethod('playAdhan');
      debugPrint('[NotifService] ✅ playAdhan invoked via MethodChannel');
    } catch (e) {
      debugPrint('[NotifService] ⚠️ playAdhan MethodChannel error: $e');
    }
  }

  /// Stop adhan sound (called when user taps "Tutup" on notification)
  Future<void> stopAdhanSound() async {
    try {
      await _adhanChannel.invokeMethod('stopAdhan');
      debugPrint('[NotifService] ✅ stopAdhan invoked via MethodChannel');
    } catch (e) {
      debugPrint('[NotifService] ⚠️ stopAdhan MethodChannel error: $e');
    }
  }

  /// =====================================================================
  /// Build NotificationDetails — alarm-priority WITHOUT fullScreenIntent.
  ///
  /// Key changes from v5:
  ///   - REMOVED fullScreenIntent: true   → prevents app auto-launch
  ///   - REMOVED sound/playSound          → sound handled by native MediaPlayer
  ///   - category: alarm                  → Android prioritizes as time-critical
  ///   - Importance.max + Priority.max    → heads-up banner display
  /// =====================================================================
  NotificationDetails _buildNotificationDetails({
    required String channelId,
    required String body,
  }) {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == _testChannelId ? 'Uji Coba Notifikasi' : _prayerChannelName,
      channelDescription: channelId == _testChannelId
          ? 'Channel uji coba pengingat instan'
          : _prayerChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      visibility: NotificationVisibility.public,
      // alarm category tells Android this is time-critical
      category: AndroidNotificationCategory.alarm,
      // NO fullScreenIntent — prevents app from auto-launching
      fullScreenIntent: false,
      ticker: 'Pengingat Adzan',
      // v7: Play adzan sound from notification channel as reliable fallback
      // AdhanPlayerService also plays full-length via native MediaPlayer
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('adzan'),
      enableVibration: true,
      enableLights: true,
      channelShowBadge: true,
      // App icon configuration
      icon: '@mipmap/ic_launcher_round',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      color: const Color(0xFF1B5E20),
      styleInformation: BigTextStyleInformation(body),
      autoCancel: true,
      ongoing: false,
      actions: const [
        AndroidNotificationAction(
          'dismiss_action',
          '✖ Tutup',
          cancelNotification: true,
          showsUserInterface: false,
        ),
      ],
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        sound: 'adzan.mp3',
        presentSound: true,
        presentAlert: true,
        presentBadge: true,
      ),
    );
  }

  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await init();

    final details = _buildNotificationDetails(
      channelId: _testChannelId,
      body: body,
    );

    try {
      await _notificationsPlugin.show(id, title, body, details);
      debugPrint('[NotifService] showInstantNotification OK — id=$id, title=$title');
      // Play adhan sound via native MediaPlayer
      await playAdhanSound();
    } catch (e) {
      debugPrint('[NotifService] showInstantNotification ERROR: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    debugPrint('[NotifService] All notifications cancelled');
  }

  Future<void> scheduleAllPrayerTimes(
    List<PrayerItem> prayers,
    String cityName, {
    bool? isAdhanEnabled,
    bool? isIftarEnabled,
    bool? isImsakEnabled,
  }) async {
    await init();
    await cancelAllNotifications();

    final prefs = await SharedPreferences.getInstance();
    final masterOn = prefs.getBool('notif_master') ?? true;
    if (!masterOn) {
      debugPrint('[NotifService] Master notification is OFF — skipping all schedules');
      await cancelAllNotifications();
      return;
    }

    final imsakOn = isImsakEnabled ?? prefs.getBool('notif_imsak') ?? prefs.getBool('is_imsak_enabled') ?? true;
    final subuhOn = prefs.getBool('notif_subuh') ?? true;
    final dzuhurOn = prefs.getBool('notif_dzuhur') ?? true;
    final asharOn = prefs.getBool('notif_ashar') ?? true;
    final maghribOn = isIftarEnabled ?? prefs.getBool('notif_maghrib') ?? prefs.getBool('is_iftar_enabled') ?? true;
    final isyaOn = prefs.getBool('notif_isya') ?? true;
    final adhanGlobalOn = isAdhanEnabled ?? prefs.getBool('is_adhan_enabled') ?? true;

    debugPrint('[NotifService] scheduleAllPrayerTimes — city=$cityName, prayers=${prayers.length}');

    final location = tz.local;
    final nowTz = tz.TZDateTime.now(location);
    debugPrint('[NotifService] Current TZ time: $nowTz (location: ${location.name})');

    int scheduledCount = 0;

    for (int i = 0; i < prayers.length; i++) {
      final prayer = prayers[i];
      final pId = prayer.id.toLowerCase();

      // Check toggle settings per prayer
      if (pId.contains('imsak') && !imsakOn) continue;
      if (pId.contains('subuh') && (!subuhOn || !adhanGlobalOn)) continue;
      if (pId.contains('dzuhur') && (!dzuhurOn || !adhanGlobalOn)) continue;
      if (pId.contains('ashar') && (!asharOn || !adhanGlobalOn)) continue;
      if (pId.contains('maghrib') && !maghribOn) continue;
      if (pId.contains('isya') && (!isyaOn || !adhanGlobalOn)) continue;

      try {
        final timeClean = prayer.time.replaceAll(RegExp(r'[^\d:]'), '').trim();
        final parts = timeClean.split(':');
        if (parts.length < 2) continue;

        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour == null || minute == null) continue;

        // 1. Calculate EXACT prayer time
        var exactPrayerTz = tz.TZDateTime(
          location,
          nowTz.year,
          nowTz.month,
          nowTz.day,
          hour,
          minute,
        );

        if (exactPrayerTz.isBefore(nowTz)) {
          exactPrayerTz = exactPrayerTz.add(const Duration(days: 1));
        }

        // 2. Calculate 1 MINUTE BEFORE prayer time
        final oneMinBeforeTz = exactPrayerTz.subtract(const Duration(minutes: 1));

        // Prepare titles & bodies
        String preTitle;
        String preBody;
        String exactTitle;
        String exactBody;

        if (pId == 'imsak') {
          preTitle = 'Waktu Imsak 1 Menit Lagi';
          preBody = 'Pengingat ($cityName): 1 menit lagi memasuki waktu Imsak.';
          exactTitle = 'Waktu Imsak Telah Tiba';
          exactBody = 'Telah memasuki waktu Imsak untuk wilayah $cityName dan sekitarnya. Segera selesaikan sahur.';
        } else if (pId == 'maghrib') {
          preTitle = 'Buka Puasa 1 Menit Lagi';
          preBody = 'Pengingat ($cityName): 1 menit lagi memasuki waktu Maghrib & berbuka puasa.';
          exactTitle = 'Waktu Buka Puasa Telah Tiba!';
          exactBody = 'Selamat berbuka puasa untuk wilayah $cityName dan sekitarnya. Selamat menunaikan ibadah sholat Maghrib.';
        } else {
          preTitle = 'Waktu Sholat ${prayer.name} 1 Menit Lagi';
          preBody = 'Pengingat ($cityName): 1 menit lagi memasuki waktu sholat ${prayer.name}.';
          exactTitle = 'Waktu Sholat ${prayer.name} Telah Tiba';
          exactBody = 'Telah memasuki waktu sholat ${prayer.name} untuk wilayah $cityName dan sekitarnya. Mari bersiap wudhu dan sholat.';
        }

        // --- A. Schedule 1 MINUTE BEFORE Notification (ID: 100 + i) ---
        if (oneMinBeforeTz.isAfter(nowTz)) {
          final scheduled = await _trySchedule(
            id: 100 + i,
            title: preTitle,
            body: preBody,
            scheduledTz: oneMinBeforeTz,
          );
          if (scheduled) scheduledCount++;
        }

        // --- B. Schedule EXACT PRAYER TIME Notification (ID: 200 + i) ---
        if (exactPrayerTz.isAfter(nowTz)) {
          final scheduled = await _trySchedule(
            id: 200 + i,
            title: exactTitle,
            body: exactBody,
            scheduledTz: exactPrayerTz,
          );
          if (scheduled) scheduledCount++;
        }

      } catch (e) {
        debugPrint('[NotifService] ERROR scheduling ${prayer.name}: $e');
      }
    }

    debugPrint('[NotifService] === Schedule complete: $scheduledCount notifications scheduled ===');
    await debugPendingNotifications();
  }

  /// Helper to attempt scheduling with multiple fallback modes
  Future<bool> _trySchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledTz,
  }) async {
    final details = _buildNotificationDetails(
      channelId: _prayerChannelId,
      body: body,
    );

    // Mode 1: alarmClock (highest priority on Android for wakeup)
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTz,
        details,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('[NotifService]   ✅ Scheduled (alarmClock) id=$id at $scheduledTz');
      return true;
    } catch (e) {
      debugPrint('[NotifService]   ⚠️ alarmClock failed id=$id: $e — trying exactAllowWhileIdle');
    }

    // Mode 2: exactAllowWhileIdle
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTz,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('[NotifService]   ✅ Scheduled (exactAllowWhileIdle) id=$id at $scheduledTz');
      return true;
    } catch (e) {
      debugPrint('[NotifService]   ⚠️ exactAllowWhileIdle failed id=$id: $e — trying inexact');
    }

    // Mode 3: inexactAllowWhileIdle
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTz,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('[NotifService]   ✅ Scheduled (inexact) id=$id at $scheduledTz');
      return true;
    } catch (e3) {
      debugPrint('[NotifService]   ❌ ALL schedule modes FAILED for id=$id: $e3');
      return false;
    }
  }
}
