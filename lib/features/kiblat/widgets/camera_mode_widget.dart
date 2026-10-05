import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'ar_qibla_overlay.dart';

class CameraModeWidget extends StatefulWidget {
  final double heading;
  final double qiblaAngle;
  final double distanceKm;
  final bool isAligned;
  final String cityName;
  final VoidCallback onSwitchToCompass;

  const CameraModeWidget({
    super.key,
    required this.heading,
    required this.qiblaAngle,
    required this.distanceKm,
    required this.isAligned,
    required this.cityName,
    required this.onSwitchToCompass,
  });

  @override
  State<CameraModeWidget> createState() => _CameraModeWidgetState();
}

class _CameraModeWidgetState extends State<CameraModeWidget>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isInitializing = true;
  bool _isPermissionDenied = false;
  String? _errorMessage;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _disposeCurrentController();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _disposeCurrentController();
    super.dispose();
  }

  Future<void> _disposeCurrentController() async {
    final controller = _cameraController;
    _cameraController = null;
    if (controller != null) {
      try {
        await controller.dispose();
      } catch (_) {}
    }
  }

  Future<void> _initCamera({int retryCount = 0}) async {
    if (_isDisposed || !mounted) return;

    setState(() {
      _isInitializing = true;
      _isPermissionDenied = false;
      _errorMessage = null;
    });

    try {
      // 1. Request camera permission
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted && !_isDisposed) {
          setState(() {
            _isInitializing = false;
            _isPermissionDenied = true;
          });
        }
        return;
      }

      // 2. Discover cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted && !_isDisposed) {
          setState(() {
            _isInitializing = false;
            _errorMessage = 'Kamera tidak ditemukan pada perangkat ini.';
          });
        }
        return;
      }

      // 3. Find back camera or fallback to first
      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      // Clean up previous controller if any
      await _disposeCurrentController();
      if (_isDisposed || !mounted) return;

      // 4. Initialize CameraController
      final controller = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();

      if (_isDisposed || !mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _isInitializing = false;
      });
    } catch (e) {
      // If hardware was busy closing previous session, retry once after a short delay
      if (retryCount < 1 && !_isDisposed && mounted) {
        await Future.delayed(const Duration(milliseconds: 400));
        if (!_isDisposed && mounted) {
          return _initCamera(retryCount: retryCount + 1);
        }
      }

      if (mounted && !_isDisposed) {
        setState(() {
          _isInitializing = false;
          _errorMessage =
              'Kamera sedang sibuk atau tidak dapat dibuka. Silakan coba lagi.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isPermissionDenied) {
      return _buildPermissionDeniedView();
    }

    if (_isInitializing) {
      return _buildLoadingView();
    }

    if (_errorMessage != null ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return _buildErrorView();
    }

    // Full screen Camera Preview with AR Overlay on top
    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera feed with proper aspect ratio filling the screen
        _buildCameraPreview(),

        // AR HUD Overlay
        ArQiblaOverlay(
          heading: widget.heading,
          qiblaAngle: widget.qiblaAngle,
          distanceKm: widget.distanceKm,
          isAligned: widget.isAligned,
          cityName: widget.cityName,
          onSwitchToCompass: widget.onSwitchToCompass,
        ),
      ],
    );
  }

  Widget _buildCameraPreview() {
    final controller = _cameraController!;
    if (!controller.value.isInitialized) {
      return const SizedBox.shrink();
    }

    final size = MediaQuery.of(context).size;
    final previewWidth =
        controller.value.previewSize?.height ?? size.width;
    final previewHeight =
        controller.value.previewSize?.width ?? size.height;

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: previewWidth,
          height: previewHeight,
          child: CameraPreview(controller),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Container(
      color: const Color(0xFF0F172A),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF10B981),
            ),
            SizedBox(height: 16),
            Text(
              'Menyiapkan Kamera AR...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedView() {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.no_photography_rounded,
                size: 48,
                color: Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Izin Kamera Diperlukan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Untuk menggunakan fitur AR petunjuk arah kiblat, mohon berikan izin akses kamera.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: widget.onSwitchToCompass,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Mode Kompas'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    await openAppSettings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Buka Pengaturan',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              size: 48,
              color: Color(0xFFF59E0B),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Gagal memuat kamera AR',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: widget.onSwitchToCompass,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Ke Kompas 2D'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _initCamera(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text(
                    'Coba Lagi',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
