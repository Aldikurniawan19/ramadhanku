import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';

class QiblaCalculator {
  static const double kaabaLat = 21.422487;
  static const double kaabaLng = 39.826206;

  /// Default Indonesia Qibla angle (~295.0°)
  static const double defaultQiblaAngle = 295.0;

  /// Default distance from Jakarta to Kaaba in Km
  static const double defaultDistanceKm = 8257.0;

  /// Calculate the Qibla bearing from a given latitude and longitude in degrees (0-360°)
  static double calculateBearing(double lat, double lng) {
    if (lat == 0.0 && lng == 0.0) return defaultQiblaAngle;

    final double phi1 = lat * (math.pi / 180.0);
    final double phi2 = kaabaLat * (math.pi / 180.0);
    final double lam1 = lng * (math.pi / 180.0);
    final double lam2 = kaabaLng * (math.pi / 180.0);

    final double y = math.sin(lam2 - lam1);
    final double x = math.cos(phi1) * math.tan(phi2) -
        math.sin(phi1) * math.cos(lam2 - lam1);

    double qibla = math.atan2(y, x) * (180.0 / math.pi);
    return (qibla + 360.0) % 360.0;
  }

  /// Calculate distance in Kilometers from a given coordinate to the Kaaba
  static double calculateDistanceKm(double lat, double lng) {
    if (lat == 0.0 && lng == 0.0) return defaultDistanceKm;
    final distanceMeters = Geolocator.distanceBetween(
      lat,
      lng,
      kaabaLat,
      kaabaLng,
    );
    return distanceMeters / 1000.0;
  }

  /// Format distance into readable string (e.g. "8.257 km")
  static String formatDistanceKm(double km) {
    return '${km.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        )} km';
  }

  /// Calculate normalized difference between qibla angle and current heading
  /// Result is between -180 and +180 degrees
  /// Positive means target is to the right (turn clockwise)
  /// Negative means target is to the left (turn counter-clockwise)
  static double getOffsetFromHeading(double heading, double qiblaAngle) {
    double diff = (qiblaAngle - heading) % 360.0;
    if (diff > 180.0) diff -= 360.0;
    if (diff < -180.0) diff += 360.0;
    return diff;
  }

  /// Check if current heading aligns with Qibla within tolerance (e.g. 5 degrees)
  static bool isAligned(double heading, double qiblaAngle, {double tolerance = 5.0}) {
    final offset = getOffsetFromHeading(heading, qiblaAngle);
    return offset.abs() <= tolerance;
  }

  /// Get Indonesian cardinal direction label
  static String getDirectionLabel(double degree) {
    final d = (degree % 360.0 + 360.0) % 360.0;
    if (d >= 337.5 || d < 22.5) return 'Utara (N)';
    if (d >= 22.5 && d < 67.5) return 'Timur Laut (NE)';
    if (d >= 67.5 && d < 112.5) return 'Timur (E)';
    if (d >= 112.5 && d < 157.5) return 'Tenggara (SE)';
    if (d >= 157.5 && d < 202.5) return 'Selatan (S)';
    if (d >= 202.5 && d < 247.5) return 'Barat Daya (SW)';
    if (d >= 247.5 && d < 292.5) return 'Barat (W)';
    return 'Barat Laut (NW)';
  }
}
