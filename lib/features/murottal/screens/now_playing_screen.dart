import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/surah_model.dart';
import '../../../providers/quran_provider.dart';
import '../widgets/ayat_lyric_card.dart';
import '../widgets/murottal_player_controls.dart';
import '../widgets/murottal_seek_bar.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const NowPlayingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final isClosing = animation.status == AnimationStatus.reverse;
          final curve = isClosing ? Curves.easeInCubic : Curves.easeOutCubic;

          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: curve,
            reverseCurve: Curves.easeInCubic,
          );

          final slideAnimation = Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(curvedAnimation);

          final scaleAnimation = Tween<double>(
            begin: 0.84,
            end: 1.0,
          ).animate(curvedAnimation);

          final fadeAnimation = Tween<double>(
            begin: 0.2,
            end: 1.0,
          ).animate(curvedAnimation);

          return SlideTransition(
            position: slideAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              alignment: Alignment.bottomCenter,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 340),
        fullscreenDialog: true,
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuranProvider>(
      builder: (context, quranProv, child) {
        final playingSurah = quranProv.playingSurah;
        final playingAyats = quranProv.playingAyatList;
        final currentAyat = quranProv.currentPlayingAyat;
        final currentAyatIndex = quranProv.currentAyatIndex;

        return Scaffold(
          backgroundColor: const Color(0xFF041613),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0F3E35),
                  Color(0xFF082721),
                  Color(0xFF031411),
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // 1. Spotify-Style Header (Back chevron, Centered Title & Subtitle, Qari Icon)
                  _buildHeader(context, quranProv, playingSurah),

                  // 2. Full-Screen Spotify Lyrics Stream (Vertical scrolling verses)
                  Expanded(
                    child: AyatLyricCard(
                      ayatList: playingAyats,
                      currentAyat: currentAyat,
                      surah: playingSurah,
                      currentAyatIndex: currentAyatIndex,
                      activeWordIndex: quranProv.activeWordIndex,
                      isLoading: quranProv.isAudioLoading,
                      onSelectAyat: (index) {
                        quranProv.seekToAyat(index);
                      },
                    ),
                  ),

                  // 3. Spotify Bottom Controls Area
                  _buildBottomControls(context, quranProv, playingSurah),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    QuranProvider quranProv,
    SurahModel? playingSurah,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 180) {
          Navigator.of(context).pop();
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle pill
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Collapse Down Button
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                  tooltip: 'Tutup',
                ),

                // Centered Track & Artist Header
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        playingSurah != null
                            ? '${playingSurah.nomor}. ${playingSurah.namaLatin}'
                            : 'Murottal Al-Qur\'an',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        quranProv.currentQariName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Right balance spacer
                const SizedBox(width: 48, height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(
    BuildContext context,
    QuranProvider quranProv,
    SurahModel? playingSurah,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini Action Row above seekbar (Qari selector pill + Bookmark)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Qari badge pill
              GestureDetector(
                onTap: () => _showQariSelectionSheet(context, quranProv),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF134E44).withOpacity(0.75),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.accentGold.withOpacity(0.35),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.graphic_eq_rounded,
                        size: 14,
                        color: AppColors.accentGold,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Suara: ${quranProv.currentQariName}',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.swap_vert_rounded,
                        size: 16,
                        color: AppColors.accentGold,
                      ),
                    ],
                  ),
                ),
              ),

              // Bookmark icon
              if (playingSurah != null)
                IconButton(
                  onPressed: () => quranProv.toggleBookmark(playingSurah.nomor),
                  icon: Icon(
                    quranProv.isBookmarked(playingSurah.nomor)
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: quranProv.isBookmarked(playingSurah.nomor)
                        ? AppColors.accentGold
                        : Colors.white.withOpacity(0.65),
                    size: 22,
                  ),
                  tooltip: 'Bookmark Surah',
                ),
            ],
          ),
          const SizedBox(height: 4),

          // Spotify-Style Seek Bar
          MurottalSeekBar(
            positionDataStream: quranProv.positionDataStream,
            onSeek: (pos) => quranProv.seekAudio(pos),
          ),
          const SizedBox(height: 8),

          // Primary Controls Row (Auto-next, Prev, Large Circular Play/Pause, Next, Repeat)
          MurottalPlayerControls(
            isPlaying: quranProv.isPlayingAudio,
            isLoading: quranProv.isAudioLoading,
            autoNextSurah: quranProv.autoNextSurah,
            repeatMode: quranProv.repeatMode,
            onPlayPause: () => quranProv.togglePlayPause(),
            onNext: () => quranProv.nextSurah(),
            onPrevious: () => quranProv.previousSurah(),
            onToggleRepeat: () => quranProv.toggleRepeatMode(),
            onToggleAutoNext: () => quranProv.toggleAutoNextSurah(),
          ),
        ],
      ),
    );
  }

  void _showQariSelectionSheet(BuildContext context, QuranProvider quranProv) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF092922),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 30,
                offset: Offset(0, -6),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pill Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  const Icon(
                    Icons.record_voice_over_rounded,
                    color: AppColors.accentGold,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Pilih Suara Qari (Pelantun Murottal)',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Ketuk nama Qari untuk mendengarkan suara pelantun favorit Anda',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),

              // Qari options
              ...QuranProvider.qariList.map((qari) {
                final isSelected = quranProv.selectedQari == qari['key'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF134E44)
                        : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accentGold
                          : Colors.white.withOpacity(0.08),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 2,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: isSelected
                          ? AppColors.accentGold
                          : Colors.white.withOpacity(0.1),
                      child: Icon(
                        Icons.person_rounded,
                        color: isSelected
                            ? const Color(0xFF063D2E)
                            : Colors.white70,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      qari['name']!,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.accentGold,
                            size: 22,
                          )
                        : null,
                    onTap: () {
                      quranProv.setSelectedQari(qari['key']!);
                      Navigator.of(context).pop();
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
