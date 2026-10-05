import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_back_button.dart';
import '../../../providers/prayer_provider.dart';
import '../services/orientation_service.dart';
import '../utils/qibla_calculator.dart';
import '../widgets/camera_mode_widget.dart';
import '../widgets/compass_mode_widget.dart';

class KiblatScreen extends StatefulWidget {
  const KiblatScreen({super.key});

  @override
  State<KiblatScreen> createState() => _KiblatScreenState();
}

class _KiblatScreenState extends State<KiblatScreen> {
  StreamSubscription<CompassEvent>? _compassSubscription;
  StreamSubscription<DeviceOrientationMode>? _orientationSubscription;
  late final OrientationService _orientationService;

  double? _heading;
  double _qiblaAngle = QiblaCalculator.defaultQiblaAngle;
  double _distanceKm = QiblaCalculator.defaultDistanceKm;
  bool _hasCompassSensor = true;
  bool _wasAligned = false;

  DeviceOrientationMode _sensorMode = DeviceOrientationMode.flat;
  DeviceOrientationMode? _manualOverrideMode;

  DeviceOrientationMode get _effectiveMode =>
      _manualOverrideMode ?? _sensorMode;

  @override
  void initState() {
    super.initState();
    _orientationService = OrientationService();
    _initCompassAndLocation();
    _initOrientationDetection();
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _orientationSubscription?.cancel();
    _orientationService.dispose();
    super.dispose();
  }

  void _initOrientationDetection() {
    _orientationSubscription =
        _orientationService.modeStream.listen((newMode) {
      if (mounted) {
        setState(() {
          _sensorMode = newMode;
          // Clear manual override when user physically tilts the device
          _manualOverrideMode = null;
        });
      }
    });
    _orientationService.startListening();
  }

  void _initCompassAndLocation() {
    // 1. Listen to real-time device compass sensor events
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (mounted) {
        final headingVal = event.heading;
        setState(() {
          _heading = headingVal;
          _hasCompassSensor = headingVal != null;
        });

        // Trigger subtle haptic feedback when user aligns with Qibla
        if (headingVal != null) {
          final isAligned =
              QiblaCalculator.isAligned(headingVal, _qiblaAngle);

          if (isAligned && !_wasAligned) {
            HapticFeedback.mediumImpact();
            _wasAligned = true;
          } else if (!isAligned && _wasAligned) {
            _wasAligned = false;
          }
        }
      }
    });

    // 2. Fetch user location and calculate exact Qibla bearing & distance
    _calculateLocationQibla();
  }

  Future<void> _calculateLocationQibla() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.low),
      );
      final double lat = pos.latitude;
      final double lng = pos.longitude;

      if (lat != 0.0 || lng != 0.0) {
        final calculatedQibla = QiblaCalculator.calculateBearing(lat, lng);
        final calculatedDistance =
            QiblaCalculator.calculateDistanceKm(lat, lng);
        if (mounted) {
          setState(() {
            _qiblaAngle = calculatedQibla;
            _distanceKm = calculatedDistance;
          });
        }
      }
    } catch (_) {
      // Keep defaults if location permission is not granted
    }
  }

  void _switchToMode(DeviceOrientationMode mode) {
    setState(() {
      _manualOverrideMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentHeading = _heading ?? 0.0;
    final isAligned = _hasCompassSensor &&
        QiblaCalculator.isAligned(currentHeading, _qiblaAngle);

    return Consumer<PrayerProvider>(
      builder: (context, prayerProv, child) {
        final city = prayerProv.currentCity.isNotEmpty
            ? prayerProv.currentCity
            : 'Jakarta, Indonesia';

        final isCameraMode = _effectiveMode == DeviceOrientationMode.upright;

        return Scaffold(
          backgroundColor: isCameraMode ? Colors.black : Colors.transparent,
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            child: isCameraMode
                ? _buildCameraView(currentHeading, isAligned, city)
                : _buildCompassView(currentHeading, isAligned, city),
          ),
        );
      },
    );
  }

  Widget _buildCompassView(
    double currentHeading,
    bool isAligned,
    String city,
  ) {
    return Container(
      key: const ValueKey('compass_view'),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/bgKompas.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leadingWidth: 60,
          leading: const Padding(
            padding: EdgeInsets.only(left: 8),
            child: GlassBackButton(),
          ),
          centerTitle: true,
          title: const Text(
            'Arah Kiblat',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          actions: [
            // Quick Button to open AR Camera
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                tooltip: 'Buka Kamera AR',
                onPressed: () =>
                    _switchToMode(DeviceOrientationMode.upright),
                icon: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryMedium),
                  ),
                  child: const Icon(
                    Icons.view_in_ar_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: CompassModeWidget(
          heading: currentHeading,
          qiblaAngle: _qiblaAngle,
          distanceKm: _distanceKm,
          hasCompassSensor: _hasCompassSensor,
          isAligned: isAligned,
          cityName: city,
          onSwitchToCamera: () =>
              _switchToMode(DeviceOrientationMode.upright),
        ),
      ),
    );
  }

  Widget _buildCameraView(
    double currentHeading,
    bool isAligned,
    String city,
  ) {
    return Stack(
      key: const ValueKey('camera_view'),
      children: [
        // Camera Viewport & AR Overlay
        CameraModeWidget(
          heading: currentHeading,
          qiblaAngle: _qiblaAngle,
          distanceKm: _distanceKm,
          isAligned: isAligned,
          cityName: city,
          onSwitchToCompass: () =>
              _switchToMode(DeviceOrientationMode.flat),
        ),

        // Back Button floating on top left
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12,
          child: const GlassBackButton(),
        ),
      ],
    );
  }
}
