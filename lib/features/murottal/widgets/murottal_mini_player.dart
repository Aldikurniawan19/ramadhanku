import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/quran_provider.dart';
import '../models/position_data.dart';
import '../screens/now_playing_screen.dart';

class MurottalMiniPlayer extends StatefulWidget {
  final double bottomMargin;

  const MurottalMiniPlayer({
    super.key,
    this.bottomMargin = 0,
  });

  @override
  State<MurottalMiniPlayer> createState() => _MurottalMiniPlayerState();
}

class _MurottalMiniPlayerState extends State<MurottalMiniPlayer> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    NowPlayingScreen.show(context);
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuranProvider>(
      builder: (context, quranProv, child) {
        final playingSurah = quranProv.playingSurah;
        final isAudioActive = quranProv.isPlayingAudio ||
            quranProv.isAudioLoading ||
            (playingSurah != null && quranProv.isPlayingFullSurah);

        final isVisible = isAudioActive && playingSurah != null;

        if (!isVisible) {
          return const SizedBox.shrink();
        }

        return AnimatedSlide(
          duration: const Duration(milliseconds: 340),
          curve: Curves.easeOutCubic,
          offset: Offset.zero,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            opacity: 1.0,
            child: Padding(
              padding: EdgeInsets.only(
                left: 14,
                right: 14,
                bottom: widget.bottomMargin + 8,
              ),
              child: AnimatedScale(
                scale: _isPressed ? 0.94 : 1.0,
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOutCubic,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C3830),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.accentGold.withOpacity(0.4),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: AppColors.accentGold.withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: GestureDetector(
                        onTapDown: _onTapDown,
                        onTapUp: _onTapUp,
                        onTapCancel: _onTapCancel,
                        behavior: HitTestBehavior.opaque,
                        child: Stack(
                          children: [
                            // Mini Player Content
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  // Left Visual Avatar / Icon
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppColors.accentGold
                                          .withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: AppColors.accentGold
                                            .withOpacity(0.3),
                                      ),
                                    ),
                                    child: Center(
                                      child: quranProv.isAudioLoading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.4,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  AppColors.accentGold,
                                                ),
                                              ),
                                            )
                                          : const Icon(
                                              Icons.graphic_eq_rounded,
                                              color: AppColors.accentGold,
                                              size: 24,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Surah & Qari Info (Super Simple & Clean)
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          playingSurah.namaLatin,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.plusJakartaSans(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          quranProv.currentQariName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.plusJakartaSans(
                                            color:
                                                Colors.white.withOpacity(0.65),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Actions: Play/Pause, Next, Close
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Play / Pause
                                      IconButton(
                                        onPressed: () =>
                                            quranProv.togglePlayPause(),
                                        icon: Icon(
                                          quranProv.isPlayingAudio
                                              ? Icons
                                                  .pause_circle_filled_rounded
                                              : Icons.play_circle_fill_rounded,
                                          color: AppColors.accentGold,
                                          size: 38,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      const SizedBox(width: 8),

                                      // Next Surah
                                      IconButton(
                                        onPressed: () => quranProv.nextSurah(),
                                        icon: Icon(
                                          Icons.skip_next_rounded,
                                          color: Colors.white.withOpacity(0.85),
                                          size: 28,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Surah Berikutnya',
                                      ),
                                      const SizedBox(width: 6),

                                      // Close
                                      IconButton(
                                        onPressed: () => quranProv.stopAudio(),
                                        icon: Icon(
                                          Icons.close_rounded,
                                          color: Colors.white.withOpacity(0.5),
                                          size: 22,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Tutup Pemutar',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Bottom Progress Line
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: StreamBuilder<PositionData>(
                                stream: quranProv.positionDataStream,
                                builder: (context, snapshot) {
                                  final data = snapshot.data;
                                  final double progress = (data != null &&
                                          data.duration.inMilliseconds > 0)
                                      ? (data.position.inMilliseconds /
                                              data.duration.inMilliseconds)
                                          .clamp(0.0, 1.0)
                                      : 0.0;

                                  return LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 3.0,
                                    backgroundColor:
                                        Colors.white.withOpacity(0.1),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                      AppColors.accentGold,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
