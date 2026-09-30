import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// =====================================================================
/// PrayerCacheService
///
/// Manages local caching of multi-day prayer schedules in SharedPreferences.
/// This allows the app to schedule notifications for multiple days ahead,
/// so even if the user doesn't open the app for several days, prayer
/// notifications will continue to fire.
///
/// Data structure stored:
///   'cached_prayers_YYYY-MM-DD' → JSON list of prayer times for that date
///   'cached_prayers_city' → city name for the cached prayers
///   'cached_prayers_dates' → JSON list of date strings that are cached
///   'last_app_opened' → ISO8601 timestamp of last app open
///   'last_schedule_refresh' → ISO8601 timestamp of last background refresh
/// =====================================================================
class PrayerCacheService {
  static const String _keyCachedCity = 'cached_prayers_city';
  static const String _keyCachedDates = 'cached_prayers_dates';
  static const String _keyLastAppOpened = 'last_app_opened';
  static const String _keyLastScheduleRefresh = 'last_schedule_refresh';

  /// Save prayer times for a specific date.
  /// [date] format: 'YYYY-MM-DD'
  /// [prayers] is a list of maps with keys: id, name, time
  static Future<void> savePrayersForDate(
    String date,
    List<Map<String, String>> prayers,
    String cityName,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_prayers_$date', jsonEncode(prayers));
    await prefs.setString(_keyCachedCity, cityName);

    // Update the list of cached dates
    final existingDates = await getCachedDates();
    if (!existingDates.contains(date)) {
      existingDates.add(date);
      existingDates.sort();
      await prefs.setStringList(_keyCachedDates, existingDates);
    }
    debugPrint('[PrayerCache] Saved ${prayers.length} prayers for $date ($cityName)');
  }

  /// Get prayer times for a specific date.
  /// Returns null if not cached.
  static Future<List<Map<String, String>>?> getPrayersForDate(String date) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('cached_prayers_$date');
    if (json == null) return null;

    try {
      final List<dynamic> decoded = jsonDecode(json);
      return decoded.map((e) => Map<String, String>.from(e as Map)).toList();
    } catch (e) {
      debugPrint('[PrayerCache] Error decoding prayers for $date: $e');
      return null;
    }
  }

  /// Get list of all cached date strings (sorted).
  static Future<List<String>> getCachedDates() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyCachedDates) ?? [];
  }

  /// Get the cached city name.
  static Future<String?> getCachedCity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCachedCity);
  }

  /// Check how many days of cached schedules remain from today onward.
  static Future<int> getRemainingCachedDays() async {
    final cachedDates = await getCachedDates();
    final today = DateTime.now();
    final todayStr = _formatDate(today);

    int remaining = 0;
    for (final dateStr in cachedDates) {
      if (dateStr.compareTo(todayStr) >= 0) {
        remaining++;
      }
    }
    return remaining;
  }

  /// Check if schedule refresh is needed.
  /// Returns true if remaining cached days <= 2 (need to download more).
  static Future<bool> needsRefresh() async {
    final remaining = await getRemainingCachedDays();
    debugPrint('[PrayerCache] Remaining cached days: $remaining');
    return remaining <= 2;
  }

  /// Clean up old cached dates (before today).
  static Future<void> cleanupOldDates() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedDates = await getCachedDates();
    final today = DateTime.now();
    final todayStr = _formatDate(today);

    final datesToRemove = <String>[];
    for (final dateStr in cachedDates) {
      if (dateStr.compareTo(todayStr) < 0) {
        datesToRemove.add(dateStr);
      }
    }

    for (final date in datesToRemove) {
      await prefs.remove('cached_prayers_$date');
      cachedDates.remove(date);
    }

    if (datesToRemove.isNotEmpty) {
      await prefs.setStringList(_keyCachedDates, cachedDates);
      debugPrint('[PrayerCache] Cleaned up ${datesToRemove.length} old dates');
    }
  }

  /// Record that the user opened the app.
  static Future<void> recordAppOpened() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastAppOpened, DateTime.now().toIso8601String());
    debugPrint('[PrayerCache] Recorded app opened');
  }

  /// Get when the user last opened the app.
  static Future<DateTime?> getLastAppOpened() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyLastAppOpened);
    if (str == null) return null;
    try {
      return DateTime.parse(str);
    } catch (_) {
      return null;
    }
  }

  /// Check if the user hasn't opened the app for [days] or more.
  static Future<bool> hasNotOpenedForDays(int days) async {
    final lastOpened = await getLastAppOpened();
    if (lastOpened == null) return true; // Never opened = definitely overdue
    final diff = DateTime.now().difference(lastOpened);
    return diff.inDays >= days;
  }

  /// Record the last time a background schedule refresh was done.
  static Future<void> recordScheduleRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastScheduleRefresh, DateTime.now().toIso8601String());
  }

  /// Get the last schedule refresh time.
  static Future<DateTime?> getLastScheduleRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyLastScheduleRefresh);
    if (str == null) return null;
    try {
      return DateTime.parse(str);
    } catch (_) {
      return null;
    }
  }

  /// Format a DateTime to YYYY-MM-DD string.
  static String _formatDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  /// Get date string for N days from now.
  static String getDateString(int daysFromNow) {
    final dt = DateTime.now().add(Duration(days: daysFromNow));
    return _formatDate(dt);
  }

  /// Get today's date string.
  static String get todayString => _formatDate(DateTime.now());
}
