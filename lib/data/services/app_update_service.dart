import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_installer/app_installer.dart';

class AppUpdateInfo {
  final String latestVersion;
  final String currentVersion;
  final String downloadUrl;
  final String releaseName;
  final String releaseNotes;
  final int fileSize;
  final DateTime? publishedAt;
  final bool isUpdateAvailable;

  const AppUpdateInfo({
    required this.latestVersion,
    required this.currentVersion,
    required this.downloadUrl,
    required this.releaseName,
    required this.releaseNotes,
    required this.fileSize,
    this.publishedAt,
    required this.isUpdateAvailable,
  });

  String get formattedFileSize {
    if (fileSize <= 0) return '';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class AppUpdateService {
  static const String _owner = 'Aldikurniawan19';
  static const String _repo = 'ramadhanku';
  static const String _apiUrl =
      'https://api.github.com/repos/$_owner/$_repo/releases/latest';
  static const String _prefKeySkippedVersion = 'skipped_update_version';

  static CancelToken? _downloadCancelToken;

  /// Check whether an update is available from GitHub Releases.
  /// If [checkSkipped] is true, returns null if user chose to skip this version.
  static Future<AppUpdateInfo?> checkForUpdate({
    bool checkSkipped = false,
  }) async {
    try {
      // 1. Get current installed version
      String currentVersion = '2.0.0';
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        currentVersion = packageInfo.version;
      } catch (e) {
        debugPrint('[AppUpdateService] Failed to get package info: $e');
      }

      // 2. Query GitHub Releases API
      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'RamadhanApp-Flutter',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint(
            '[AppUpdateService] GitHub API returned status: ${response.statusCode}');
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      final tagName = (data['tag_name'] as String? ?? '').trim();
      final cleanLatestVersion = tagName.startsWith('v') || tagName.startsWith('V')
          ? tagName.substring(1)
          : tagName;

      if (cleanLatestVersion.isEmpty) return null;

      // 3. Find APK asset
      final assets = (data['assets'] as List<dynamic>?) ?? [];
      String downloadUrl = '';
      int fileSize = 0;

      for (final asset in assets) {
        final name = (asset['name'] as String? ?? '').toLowerCase();
        if (name.endsWith('.apk')) {
          downloadUrl = asset['browser_download_url'] as String? ?? '';
          fileSize = (asset['size'] as num?)?.toInt() ?? 0;
          break;
        }
      }

      // If no direct APK asset found in release, fallback to html_url
      if (downloadUrl.isEmpty) {
        downloadUrl = data['html_url'] as String? ?? '';
      }

      final releaseName = data['name'] as String? ?? 'Versi $cleanLatestVersion';
      final releaseNotes = data['body'] as String? ?? '';
      final publishedAtStr = data['published_at'] as String?;
      final publishedAt =
          publishedAtStr != null ? DateTime.tryParse(publishedAtStr) : null;

      final isNewer = isVersionNewer(cleanLatestVersion, currentVersion);

      // Check if user previously skipped this version
      if (checkSkipped && isNewer) {
        final prefs = await SharedPreferences.getInstance();
        final skippedVersion = prefs.getString(_prefKeySkippedVersion);
        if (skippedVersion == cleanLatestVersion) {
          debugPrint(
              '[AppUpdateService] Version $cleanLatestVersion was skipped by user.');
          return null;
        }
      }

      return AppUpdateInfo(
        latestVersion: cleanLatestVersion,
        currentVersion: currentVersion,
        downloadUrl: downloadUrl,
        releaseName: releaseName,
        releaseNotes: releaseNotes,
        fileSize: fileSize,
        publishedAt: publishedAt,
        isUpdateAvailable: isNewer,
      );
    } catch (e) {
      debugPrint('[AppUpdateService] Error checking update: $e');
      return null;
    }
  }

  /// Compare two semantic version strings (e.g. "2.0.2" vs "2.0.0").
  /// Returns true if [latest] is strictly greater than [current].
  static bool isVersionNewer(String latest, String current) {
    try {
      final cleanLatest = latest.split('+').first.split('-').first.trim();
      final cleanCurrent = current.split('+').first.split('-').first.trim();

      final latestParts = cleanLatest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final currentParts = cleanCurrent.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      final maxLen = latestParts.length > currentParts.length
          ? latestParts.length
          : currentParts.length;

      for (int i = 0; i < maxLen; i++) {
        final l = i < latestParts.length ? latestParts[i] : 0;
        final c = i < currentParts.length ? currentParts[i] : 0;
        if (l > c) return true;
        if (l < c) return false;
      }
      return false;
    } catch (e) {
      debugPrint('[AppUpdateService] Error comparing versions: $e');
      return false;
    }
  }

  /// Download APK with progress notification and start Android installer
  static Future<void> downloadAndInstall({
    required String downloadUrl,
    required void Function(int received, int total, double progress) onProgress,
    required void Function(String message) onError,
    required void Function() onCompleted,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/RamadhanApp-update.apk';

      // Delete previous downloaded APK if exists
      final oldFile = File(savePath);
      if (await oldFile.exists()) {
        try {
          await oldFile.delete();
        } catch (_) {}
      }

      _downloadCancelToken = CancelToken();

      final dio = Dio();
      await dio.download(
        downloadUrl,
        savePath,
        cancelToken: _downloadCancelToken,
        onReceiveProgress: (received, total) {
          final progress = total > 0 ? received / total : 0.0;
          onProgress(received, total, progress.clamp(0.0, 1.0));
        },
      );

      final downloadedFile = File(savePath);
      if (!await downloadedFile.exists() || await downloadedFile.length() == 0) {
        onError('File unduhan tidak ditemukan atau kosong.');
        return;
      }

      onCompleted();

      // Trigger system package installer
      await AppInstaller.installApk(savePath);
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        debugPrint('[AppUpdateService] Download cancelled by user.');
        return;
      }
      debugPrint('[AppUpdateService] Download/install error: $e');
      onError('Gagal mengunduh pembaruan: ${e.toString()}');
    } finally {
      _downloadCancelToken = null;
    }
  }

  /// Cancel ongoing download
  static void cancelDownload() {
    _downloadCancelToken?.cancel('Cancelled by user');
    _downloadCancelToken = null;
  }

  /// Save skipped version to SharedPreferences
  static Future<void> setSkippedVersion(String version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeySkippedVersion, version);
    } catch (e) {
      debugPrint('[AppUpdateService] Failed to set skipped version: $e');
    }
  }

  /// Clear skipped version preference
  static Future<void> clearSkippedVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKeySkippedVersion);
    } catch (e) {
      debugPrint('[AppUpdateService] Failed to clear skipped version: $e');
    }
  }
}
