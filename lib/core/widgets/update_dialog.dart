import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/services/app_update_service.dart';
import '../theme/app_colors.dart';

enum UpdateDialogState {
  ready,
  downloading,
  installing,
  error,
}

class UpdateDialog extends StatefulWidget {
  final AppUpdateInfo updateInfo;
  final bool isMandatory;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
    this.isMandatory = false,
  });

  /// Static helper to show update as a locked/controlled Bottom Sheet
  static Future<void> show(
    BuildContext context, {
    required AppUpdateInfo updateInfo,
    bool isMandatory = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isDismissible: false, // Prevents closing by tapping outside during operation
      enableDrag: false,    // Prevents closing by dragging down during operation
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UpdateDialog(
        updateInfo: updateInfo,
        isMandatory: isMandatory,
      ),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  UpdateDialogState _state = UpdateDialogState.ready;
  double _progress = 0.0;
  int _receivedBytes = 0;
  int _totalBytes = 0;
  String _errorMessage = '';
  bool _dontAskAgain = false;

  void _startDownload() {
    setState(() {
      _state = UpdateDialogState.downloading;
      _progress = 0.0;
      _errorMessage = '';
    });

    AppUpdateService.downloadAndInstall(
      downloadUrl: widget.updateInfo.downloadUrl,
      onProgress: (received, total, progress) {
        if (mounted) {
          setState(() {
            _receivedBytes = received;
            _totalBytes = total;
            _progress = progress;
          });
        }
      },
      onError: (msg) {
        if (mounted) {
          setState(() {
            _state = UpdateDialogState.error;
            _errorMessage = msg;
          });
        }
      },
      onCompleted: () {
        if (mounted) {
          setState(() {
            _state = UpdateDialogState.installing;
          });
        }
      },
    );
  }

  void _cancelDownload() {
    AppUpdateService.cancelDownload();
    setState(() {
      _state = UpdateDialogState.ready;
      _progress = 0.0;
    });
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 MB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final isDownloadingOrInstalling = _state == UpdateDialogState.downloading ||
        _state == UpdateDialogState.installing;

    return PopScope(
      // Modal completely locked during downloading/installing.
      // Can ONLY be dismissed in ready/error state, or if user explicitly presses cancel button.
      canPop: !widget.isMandatory && !isDownloadingOrInstalling,
      onPopInvokedWithResult: (didPop, result) {
        // No accidental dismiss allowed
      },
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 32,
                offset: Offset(0, -8),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Drag Handle Bar / Close Row
                  Padding(
                    padding: const EdgeInsets.only(top: 10, left: 20, right: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 32),
                        Container(
                          width: 42,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        // Close "X" button available only when not downloading/installing
                        if (!widget.isMandatory && !isDownloadingOrInstalling)
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded),
                            iconSize: 22,
                            color: AppColors.textMuted,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          )
                        else
                          const SizedBox(width: 32, height: 32),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Header Banner
                  _buildHeader(),

                  // Dynamic Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _buildCurrentStateView(),
                    ),
                  ),

                  // Actions
                  _buildActions(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -15,
            child: Icon(
              Icons.system_update_alt_rounded,
              size: 80,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.2,
                  ),
                ),
                child: const Icon(
                  Icons.rocket_launch_rounded,
                  color: AppColors.accentGold,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pembaruan Aplikasi',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Versi v${widget.updateInfo.latestVersion} siap dipasang',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Version pill badge
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'v${widget.updateInfo.currentVersion}',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 5),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: 13,
                                color: AppColors.accentGold.withOpacity(0.9),
                              ),
                            ),
                            Text(
                              'v${widget.updateInfo.latestVersion}',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.updateInfo.formattedFileSize.isNotEmpty) ...[
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 5),
                                width: 3.5,
                                height: 3.5,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Text(
                                widget.updateInfo.formattedFileSize,
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.accentGold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStateView() {
    switch (_state) {
      case UpdateDialogState.ready:
        return _buildReadyView();
      case UpdateDialogState.downloading:
        return _buildDownloadingView();
      case UpdateDialogState.installing:
        return _buildInstallingView();
      case UpdateDialogState.error:
        return _buildErrorView();
    }
  }

  Widget _buildReadyView() {
    return Column(
      key: const ValueKey('ready_view'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Intro text
        Text(
          'Aplikasi Ramadhan versi terbaru (v${widget.updateInfo.latestVersion}) telah tersedia untuk memberikan pengalaman terbaik bagi ibadah Anda:',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.textPrimary,
            fontSize: 13.5,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),

        // 3 Feature Highlight Cards
        _buildFeatureItem(
          icon: Icons.auto_awesome_rounded,
          iconColor: AppColors.accentGold,
          title: 'Pembaruan Fitur & Stabilitas',
          description: 'Peningkatan performa fitur dan perbaikan menyeluruh',
        ),
        const SizedBox(height: 8),
        _buildFeatureItem(
          icon: Icons.speed_rounded,
          iconColor: AppColors.primary,
          title: 'Navigasi Cepat & Responsif',
          description: 'Pengalaman membuka aplikasi lebih ringan dan lancar',
        ),
        const SizedBox(height: 8),
        _buildFeatureItem(
          icon: Icons.verified_user_rounded,
          iconColor: Colors.blue.shade600,
          title: 'Optimalisasi Sistem',
          description: 'Pembaruan keamanan dan keandalan aplikasi ibadah Anda',
        ),

        const SizedBox(height: 14),
        // Hint text
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.touch_app_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tekan "Update Sekarang" untuk memperbarui aplikasi secara otomatis.',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.primaryHover,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        if (!widget.isMandatory) ...[
          const SizedBox(height: 10),
          InkWell(
            onTap: () {
              setState(() {
                _dontAskAgain = !_dontAskAgain;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: Checkbox(
                      value: _dontAskAgain,
                      onChanged: (val) {
                        setState(() {
                          _dontAskAgain = val ?? false;
                        });
                      },
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Jangan ingatkan lagi untuk versi ini',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadingView() {
    final percent = (_progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        key: const ValueKey('downloading_view'),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Mengunduh pembaruan...',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                '$percent%',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _progress > 0 ? _progress : null,
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Terunduh: ${_formatBytes(_receivedBytes)}',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              Text(
                'Total: ${_totalBytes > 0 ? _formatBytes(_totalBytes) : widget.updateInfo.formattedFileSize}',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstallingView() {
    return Column(
      key: const ValueKey('installing_view'),
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: AppColors.primary,
            size: 40,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Unduhan Selesai!',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Membuka installer paket Android untuk memasang...',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.textSecondary,
            fontSize: 12.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade300),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: Colors.amber.shade900,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Catatan: Jika muncul keterangan paket bentrok, silakan uninstall aplikasi versi lama terlebih dahulu sebelum memasang pembaruan ini.',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.amber.shade900,
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildErrorView() {
    return Column(
      key: const ValueKey('error_view'),
      children: [
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline_rounded,
            color: Colors.red,
            size: 38,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Gagal Mengunduh',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.red.shade700,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _errorMessage.isNotEmpty
              ? _errorMessage
              : 'Terjadi kesalahan saat mengunduh pembaruan. Pastikan koneksi internet stabil.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.textSecondary,
            fontSize: 12.5,
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
      child: Row(
        children: [
          if (_state == UpdateDialogState.ready) ...[
            if (!widget.isMandatory)
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: () async {
                    if (_dontAskAgain) {
                      await AppUpdateService.setSkippedVersion(
                        widget.updateInfo.latestVersion,
                      );
                    }
                    if (mounted) Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.cardBorder, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Nanti Saja',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            if (!widget.isMandatory) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _startDownload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.download_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Update Sekarang',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else if (_state == UpdateDialogState.downloading) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _cancelDownload,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Colors.red,
                ),
                label: Text(
                  'Batalkan Unduhan',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.red.shade700,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.red.shade200, width: 1.2),
                  backgroundColor: Colors.red.shade50.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ] else if (_state == UpdateDialogState.installing) ...[
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Selesai',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ] else if (_state == UpdateDialogState.error) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.cardBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Tutup',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _startDownload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Coba Lagi',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
