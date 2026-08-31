import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../core/theme/app_colors.dart';

class GpsDisabledException implements Exception {
  final String message;
  GpsDisabledException([this.message = 'Layanan lokasi (GPS) pada perangkat belum diaktifkan. Mohon aktifkan GPS.']);
  @override
  String toString() => message;
}

class LocationPermissionDeniedException implements Exception {
  final String message;
  LocationPermissionDeniedException([this.message = 'Izin akses lokasi ditolak.']);
  @override
  String toString() => message;
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Prompt modal dialog to ask user to enable GPS
  static Future<void> showGpsPromptDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.location_off_rounded, color: Color(0xFFEF4444), size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'GPS Belum Aktif',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Fitur pencarian lokasi otomatis memerlukan layanan GPS. Silakan aktifkan GPS pada ponsel Anda untuk mendeteksi wilayah jadwal sholat secara presisi.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await Geolocator.openLocationSettings();
            },
            child: const Text(
              'Buka Pengaturan GPS',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> getCurrentCityName({bool promptEnableGps = true}) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (promptEnableGps) {
        await Geolocator.openLocationSettings();
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
      }
      if (!serviceEnabled) {
        throw GpsDisabledException('Layanan lokasi (GPS) pada perangkat belum diaktifkan. Mohon aktifkan GPS.');
      }
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationPermissionDeniedException('Izin akses lokasi ditolak. Mohon berikan izin lokasi untuk mendeteksi wilayah Anda.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      throw LocationPermissionDeniedException('Izin lokasi ditolak permanen. Mohon izinkan lokasi melalui Pengaturan HP.');
    }

    // Get current GPS coordinates
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );

    // Reverse geocoding to resolve GPS coordinates to City
    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isNotEmpty) {
      final place = placemarks.first;

      String? city = place.subAdministrativeArea;
      if (city == null || city.isEmpty) {
        city = place.locality;
      }
      if (city == null || city.isEmpty) {
        city = place.administrativeArea;
      }

      if (city != null && city.isNotEmpty) {
        // Strip prefixes like "Kabupaten ", "Kota ", "Kab. ", etc.
        city = city
            .replaceAll(RegExp(r'^(Kabupaten|Kota|Kab\.|Kota\.)\s*', caseSensitive: false), '')
            .trim();
        return city;
      }
    }

    return null;
  }
}
