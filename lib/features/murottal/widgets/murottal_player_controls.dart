import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/quran_provider.dart';

class MurottalPlayerControls extends StatelessWidget {
  final bool isPlaying;
  final bool isLoading;
  final bool autoNextSurah;
  final MurottalRepeatMode repeatMode;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onToggleRepeat;
  final VoidCallback onToggleAutoNext;

  const MurottalPlayerControls({
    super.key,
    required this.isPlaying,
    required this.isLoading,
    required this.autoNextSurah,
    required this.repeatMode,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
    required this.onToggleRepeat,
    required this.onToggleAutoNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 1. Auto-Next Surah Toggle (Continuous playback)
        IconButton(
          onPressed: onToggleAutoNext,
          tooltip: 'Putar Surah Selanjutnya Otomatis',
          icon: Icon(
            Icons.playlist_play_rounded,
            color: autoNextSurah
                ? AppColors.accentGold
                : Colors.white.withOpacity(0.4),
            size: 28,
          ),
        ),

        // 2. Previous Surah
        IconButton(
          onPressed: onPrevious,
          tooltip: 'Surah Sebelumnya',
          icon: const Icon(
            Icons.skip_previous_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),

        // 3. Play / Pause Main Button (Spotify-style prominent circular button)
        GestureDetector(
          onTap: onPlayPause,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD4AF37), Color(0xFFF59E0B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentGold.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.8,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF063D2E),
                        ),
                      ),
                    )
                  : Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: const Color(0xFF063D2E),
                      size: 38,
                    ),
            ),
          ),
        ),

        // 4. Next Surah
        IconButton(
          onPressed: onNext,
          tooltip: 'Surah Berikutnya',
          icon: const Icon(
            Icons.skip_next_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),

        // 5. Repeat Mode (Off -> Repeat Surah -> Repeat Ayat -> Off)
        IconButton(
          onPressed: onToggleRepeat,
          tooltip: _getRepeatTooltip(),
          icon: Icon(
            repeatMode == MurottalRepeatMode.repeatAyat
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            color: repeatMode != MurottalRepeatMode.off
                ? AppColors.accentGold
                : Colors.white.withOpacity(0.4),
            size: 26,
          ),
        ),
      ],
    );
  }

  String _getRepeatTooltip() {
    switch (repeatMode) {
      case MurottalRepeatMode.off:
        return 'Ulang: Mati';
      case MurottalRepeatMode.repeatSurah:
        return 'Ulang: Satu Surah Penuh';
      case MurottalRepeatMode.repeatAyat:
        return 'Ulang: Ayat Ini Saja (Hafalan)';
    }
  }
}
