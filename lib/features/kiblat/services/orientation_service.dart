import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

enum DeviceOrientationMode {
  flat, // Phone is laying flat or horizontal -> 2D Compass
  upright, // Phone is held upright / vertical -> AR Camera
}

class OrientationService {
  StreamSubscription<AccelerometerEvent>? _subscription;
  final StreamController<DeviceOrientationMode> _controller =
      StreamController<DeviceOrientationMode>.broadcast();

  DeviceOrientationMode _currentMode = DeviceOrientationMode.flat;
  DeviceOrientationMode? _pendingMode;
  Timer? _debounceTimer;

  /// Thresholds for switching with hysteresis (to prevent jitter near ~45 degrees)
  static const double _flatThreshold = 7.5;
  static const double _uprightThreshold = 5.0;

  /// Time the phone must remain stable in new posture before triggering switch
  static const Duration _stabilityDuration = Duration(milliseconds: 350);

  Stream<DeviceOrientationMode> get modeStream => _controller.stream;
  DeviceOrientationMode get currentMode => _currentMode;

  void startListening() {
    _subscription?.cancel();
    _debounceTimer?.cancel();

    try {
      _subscription = accelerometerEventStream().listen(
        (AccelerometerEvent event) {
          final double zAbs = event.z.abs();
          DeviceOrientationMode detectedMode = _currentMode;

          if (_currentMode == DeviceOrientationMode.flat) {
            // Must tilt upright significantly to enter AR camera mode
            if (zAbs < _uprightThreshold) {
              detectedMode = DeviceOrientationMode.upright;
            }
          } else {
            // Must lay flat significantly to return to 2D compass mode
            if (zAbs > _flatThreshold) {
              detectedMode = DeviceOrientationMode.flat;
            }
          }

          if (detectedMode != _currentMode) {
            if (_pendingMode != detectedMode) {
              _pendingMode = detectedMode;
              _debounceTimer?.cancel();
              _debounceTimer = Timer(_stabilityDuration, () {
                if (_pendingMode != null && _pendingMode != _currentMode) {
                  _currentMode = _pendingMode!;
                  _controller.add(_currentMode);
                }
              });
            }
          } else {
            // Returned to current mode before debounce completed, cancel pending switch
            _pendingMode = null;
            _debounceTimer?.cancel();
          }
        },
        onError: (error) {
          // If sensor is not supported, stay in flat mode
        },
        cancelOnError: false,
      );
    } catch (_) {
      // Sensor not available on this device
    }
  }

  void stopListening() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _subscription?.cancel();
    _subscription = null;
  }

  void dispose() {
    stopListening();
    _controller.close();
  }
}
