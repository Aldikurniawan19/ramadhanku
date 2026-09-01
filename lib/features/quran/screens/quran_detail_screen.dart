import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/modern_snack_bar.dart';
import '../../../core/widgets/glass_back_button.dart';
import '../../../core/widgets/shimmer_skeleton.dart';
import '../../../core/widgets/islamic_empty_state.dart';
import '../../../data/services/firebase_service.dart';
import '../../../providers/quran_provider.dart';
import '../../onboarding/screens/onboarding_screen.dart';
import '../screens/quran_list_screen.dart'; // Imports IslamicStarBadge & IslamicStarPainter
import '../widgets/audio_player_bar.dart';

class QuranDetailScreen extends StatelessWidget {
  final int surahNumber;
  const QuranDetailScreen({super.key, required this.surahNumber});

  @override
  Widget build(BuildContext context) {
    return Consumer<QuranProvider>(
      builder: (context, quranProv, child) {
        final surah = quranProv.currentSurah;
        final ayatList = quranProv.currentAyatList;

        return Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/bgAlquran.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              leadingWidth: 60,
              leading: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: GlassBackButton(),
              ),
              centerTitle: true,
              title: Text(
                surah?.namaLatin ?? 'Detail Surah',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              actions: const [],
            ),
            bottomNavigationBar: const AudioPlayerBar(),
            body:
                quranProv.isLoadingDetail &&
                    (surah == null || surah.nomor != surahNumber)
                ? _buildSkeletonLoader()
                : surah == null
                ? Center(
                    child: IslamicEmptyState(
                      title: 'Koneksi Internet Terputus',
                      message:
                          'Perangkat Anda harus terhubung ke jaringan internet untuk memuat dan membaca ayat Al-Qur\'an.',
                      actionLabel: 'Coba Lagi',
                      onActionPressed: () =>
                          quranProv.loadSurahDetail(surahNumber),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Column(
                            children: [
                              // 1. Surah Hero Banner Header (Exact Matching Reference Image)
                              _buildSurahHeroBanner(context, surah),

                              const SizedBox(height: 12),

                              // 2. Bismillah Banner Card (Excluding Surah At-Taubah)
                              if (surah.nomor != 9) ...[
                                _buildBismillahCard(),
                                const SizedBox(height: 16),
                              ],

                              // 3. Full Murottal Audio Player Card
                              _buildFullMurottalBar(context, quranProv, surah),

                              const SizedBox(height: 16),

                              // 4. Ayat List or Shimmer Skeleton State
                              if (quranProv.isLoadingDetail)
                                _buildSkeletonLoader()
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: ayatList.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 16),
                                  itemBuilder: (context, index) {
                                    final ayat = ayatList[index];
                                    return _buildAyatCard(
                                      context,
                                      ayat,
                                      surah,
                                      quranProv,
                                    );
                                  },
                                ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  /// Surah Hero Title Header
  Widget _buildSurahHeroBanner(BuildContext context, dynamic surah) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'سُورَةُ ${surah.nama}',
            textAlign: TextAlign.center,
            style: GoogleFonts.amiri(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF063D2E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Surat ${surah.namaLatin}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  /// Bismillah Banner Card with Islamic Rosette Medallions matching exact reference image
  Widget _buildBismillahCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: Colors.transparent,
      child: Row(
        children: [
          // Left Islamic Rosette Medallion
          SizedBox(
            width: 26,
            height: 26,
            child: CustomPaint(
              painter: IslamicRosetteOrnamentPainter(
                color: const Color(0xFFC59B27),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Divider(color: Color(0xFFD8C9B9), thickness: 1.2),
          ),
          const SizedBox(width: 12),

          // Bismillah Calligraphy
          Text(
            'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
            style: GoogleFonts.amiri(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF063D2E),
            ),
          ),

          const SizedBox(width: 12),
          const Expanded(
            child: Divider(color: Color(0xFFD8C9B9), thickness: 1.2),
          ),
          const SizedBox(width: 8),

          // Right Islamic Rosette Medallion
          SizedBox(
            width: 26,
            height: 26,
            child: CustomPaint(
              painter: IslamicRosetteOrnamentPainter(
                color: const Color(0xFFC59B27),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Single Ayat Card matching reference image
  Widget _buildAyatCard(
    BuildContext context,
    dynamic ayat,
    dynamic surah,
    QuranProvider quranProv,
  ) {
    final isPlaying =
        quranProv.playingAyatNumber == ayat.nomorAyat &&
        quranProv.isPlayingAudio &&
        !quranProv.isPlayingFullSurah;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPlaying ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPlaying ? const Color(0xFF059669) : const Color(0xFFF1F5F9),
          width: isPlaying ? 1.5 : 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Verse Number (Left) + Action Buttons [Play, Bookmark, Share, More] (Right)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Verse Number Badge
              IslamicStarBadge(arabicText: '${ayat.nomorAyat}', size: 38),

              // Top Right Actions (Play, Bookmark, Share, More)
              Row(
                children: [
                  // Play Audio Button
                  Builder(
                    builder: (context) {
                      final isAyatBuffering =
                          quranProv.playingAyatNumber == ayat.nomorAyat &&
                          !quranProv.isPlayingFullSurah &&
                          quranProv.isAudioLoading;

                      return IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                        icon: isAyatBuffering
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Color(0xFF063D2E),
                                ),
                              )
                            : Icon(
                                isPlaying
                                    ? Icons.pause_circle_filled_rounded
                                    : Icons.play_circle_fill_rounded,
                                color: isPlaying
                                    ? const Color(0xFF059669)
                                    : const Color(0xFF063D2E),
                                size: 24,
                              ),
                        onPressed: () {
                          final audioUrl =
                              ayat.audio['05'] ?? ayat.audio['01'] ?? '';
                          if (audioUrl.isNotEmpty) {
                            quranProv.playAyatAudio(ayat.nomorAyat, audioUrl);
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(width: 2),

                  // Bookmark Icon Button
                  Builder(
                    builder: (context) {
                      final isBookmarked =
                          quranProv.lastReadSurahNumber == surah.nomor &&
                          quranProv.lastReadAyatNumber == ayat.nomorAyat;
                      return IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                        icon: Icon(
                          isBookmarked
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_outline_rounded,
                          color: isBookmarked
                              ? const Color(0xFF063D2E)
                              : const Color(0xFF94A3B8),
                          size: 22,
                        ),
                        onPressed: () async {
                          final isLoggedIn = await FirebaseService()
                              .isLoggedIn();
                          if (!isLoggedIn) {
                            if (context.mounted)
                              _showRequireLoginModal(context);
                            return;
                          }
                          final estimatedJuz = ((surah.nomor * 30) / 114)
                              .round()
                              .clamp(1, 30);
                          quranProv.updateLastRead(
                            surahName: surah.namaLatin,
                            surahNumber: surah.nomor,
                            ayatNumber: ayat.nomorAyat,
                            juzNumber: estimatedJuz,
                          );
                          ModernSnackBar.show(
                            context,
                            title: 'Penanda Bacaan',
                            message:
                                'Ditandai sebagai bacaan terakhir: ${surah.namaLatin} ayat ${ayat.nomorAyat}',
                            type: SnackBarType.success,
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(width: 2),

                  // Share Button (Opens Native OS Share Modal for Chat & Social Media)
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    icon: const Icon(
                      Icons.share_outlined,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                    onPressed: () async {
                      final shareText =
                          '${ayat.teksArab}\n\n${ayat.teksIndonesia}\n\n(QS. ${surah.namaLatin}: ${ayat.nomorAyat})';
                      await Share.share(
                        shareText,
                        subject: 'QS. ${surah.namaLatin}: ${ayat.nomorAyat}',
                      );
                    },
                  ),
                  const SizedBox(width: 2),

                  // More Options Button
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    icon: const Icon(
                      Icons.more_horiz_rounded,
                      color: Color(0xFF94A3B8),
                      size: 22,
                    ),
                    onPressed: () {
                      _showAyatOptionsMenu(context, ayat, surah, quranProv);
                    },
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Arabic Verse Text (Right aligned)
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              ayat.teksArab,
              textAlign: TextAlign.right,
              style: GoogleFonts.amiri(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
                height: 2.2,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Transliteration Text (Latin reading, italic green)
          Text(
            ayat.teksLatin,
            style: const TextStyle(
              fontSize: 13.5,
              fontStyle: FontStyle.italic,
              color: Color(0xFF059669),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 6),

          // Indonesian Translation
          Text(
            ayat.teksIndonesia,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF334155),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Full Murottal Audio Player Bar
  Widget _buildFullMurottalBar(
    BuildContext context,
    QuranProvider quranProv,
    dynamic surah,
  ) {
    final isFullPlaying =
        quranProv.isPlayingFullSurah && quranProv.isPlayingAudio;
    final isFullPaused =
        quranProv.isPlayingFullSurah && !quranProv.isPlayingAudio;
    final fullAudioUrl =
        surah.audioFull['05'] ??
        surah.audioFull['01'] ??
        surah.audioFull.values.firstOrNull ??
        '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isFullPlaying ? const Color(0xFFECFDF5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFullPlaying
              ? const Color(0xFF059669)
              : const Color(0xFFF1F5F9),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isFullPlaying
                      ? const Color(0xFF063D2E)
                      : const Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.headphones_rounded,
                  color: isFullPlaying ? Colors.white : const Color(0xFF063D2E),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Murottal ${surah.namaLatin}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    isFullPlaying
                        ? 'Memutar audio full surah...'
                        : isFullPaused
                        ? 'Audio di-pause'
                        : 'Dengarkan full surah',
                    style: TextStyle(
                      fontSize: 11,
                      color: isFullPlaying
                          ? const Color(0xFF059669)
                          : const Color(0xFF64748B),
                      fontWeight: isFullPlaying
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (fullAudioUrl.isNotEmpty) {
                quranProv.playFullSurahAudio(fullAudioUrl);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Audio full surah tidak tersedia.'),
                  ),
                );
              }
            },
            icon: Icon(
              isFullPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 18,
            ),
            label: Text(
              isFullPlaying
                  ? 'Jeda'
                  : (isFullPaused ? 'Lanjut' : 'Putar Semua'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isFullPlaying
                  ? AppColors.warning
                  : const Color(0xFF063D2E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Footer Navigation between Surahs
  Widget _buildSurahNavigationFooter(
    BuildContext context,
    QuranProvider quranProv,
    dynamic surah,
  ) {
    final currentNum = surah.nomor;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (currentNum > 1)
          OutlinedButton.icon(
            onPressed: () {
              quranProv.loadSurahDetail(currentNum - 1);
            },
            icon: const Icon(Icons.chevron_left_rounded, size: 18),
            label: const Text('Surah Seb.'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF063D2E),
              side: const BorderSide(color: Color(0xFF063D2E)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          )
        else
          const SizedBox.shrink(),
        IconButton(
          icon: const Icon(
            Icons.format_list_bulleted_rounded,
            color: Color(0xFF063D2E),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        if (currentNum < 114)
          OutlinedButton.icon(
            onPressed: () {
              quranProv.loadSurahDetail(currentNum + 1);
            },
            icon: const Icon(Icons.chevron_right_rounded, size: 18),
            label: const Text('Surah Sel.'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF063D2E),
              side: const BorderSide(color: Color(0xFF063D2E)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }

  void _showAyatOptionsMenu(
    BuildContext context,
    dynamic ayat,
    dynamic surah,
    QuranProvider quranProv,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.play_circle_fill_rounded,
                    color: Color(0xFF063D2E),
                  ),
                  title: Text('Putar Audio Ayat ${ayat.nomorAyat}'),
                  onTap: () {
                    Navigator.pop(ctx);
                    final audioUrl = ayat.audio['05'] ?? ayat.audio['01'] ?? '';
                    if (audioUrl.isNotEmpty) {
                      quranProv.playAyatAudio(ayat.nomorAyat, audioUrl);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.share_rounded,
                    color: Color(0xFF063D2E),
                  ),
                  title: const Text('Bagikan Ayat ke Aplikasi Lain'),
                  onTap: () {
                    Navigator.pop(ctx);
                    final shareText =
                        '${ayat.teksArab}\n\n${ayat.teksIndonesia}\n\n(QS. ${surah.namaLatin}: ${ayat.nomorAyat})';
                    Share.share(
                      shareText,
                      subject: 'QS. ${surah.namaLatin}: ${ayat.nomorAyat}',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.copy_rounded,
                    color: Color(0xFF063D2E),
                  ),
                  title: const Text('Salin Teks Ayat & Terjemahan'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Clipboard.setData(
                      ClipboardData(
                        text:
                            '${ayat.teksArab}\n\n${ayat.teksIndonesia}\n(${surah.namaLatin}: ${ayat.nomorAyat})',
                      ),
                    );
                    ModernSnackBar.show(
                      context,
                      title: 'Disalin',
                      message: 'Ayat ${ayat.nomorAyat} berhasil disalin.',
                      type: SnackBarType.info,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Custom Shimmer Skeleton Loader for Detail Screen (matching exact layout of _buildAyatCard)
  Widget _buildSkeletonLoader() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          // 4 Ayat Cards Skeletons
          for (int i = 0; i < 4; i++) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Verse Number Badge (Left) + 4 Action Buttons (Right)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left: Single Verse Number Badge Circle
                      const ShimmerSkeletonBox(
                        width: 38,
                        height: 38,
                        borderRadius: 19,
                      ),
                      // Right: 4 Action Buttons (Play, Bookmark, Share, More)
                      Row(
                        children: const [
                          ShimmerSkeletonBox(
                            width: 26,
                            height: 26,
                            borderRadius: 13,
                          ),
                          SizedBox(width: 6),
                          ShimmerSkeletonBox(
                            width: 26,
                            height: 26,
                            borderRadius: 13,
                          ),
                          SizedBox(width: 6),
                          ShimmerSkeletonBox(
                            width: 26,
                            height: 26,
                            borderRadius: 13,
                          ),
                          SizedBox(width: 6),
                          ShimmerSkeletonBox(
                            width: 26,
                            height: 26,
                            borderRadius: 13,
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Arabic Verse Text (Right aligned)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: const [
                        ShimmerSkeletonBox(
                          width: 260,
                          height: 24,
                          borderRadius: 6,
                        ),
                        SizedBox(height: 8),
                        ShimmerSkeletonBox(
                          width: 180,
                          height: 24,
                          borderRadius: 6,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Transliteration Text (Latin reading)
                  const ShimmerSkeletonBox(
                    width: 210,
                    height: 14,
                    borderRadius: 4,
                  ),

                  const SizedBox(height: 10),

                  // Indonesian Translation (Multi-line)
                  const ShimmerSkeletonBox(
                    width: double.infinity,
                    height: 14,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 6),
                  const ShimmerSkeletonBox(
                    width: 240,
                    height: 14,
                    borderRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

/// CustomPainter for Authentic Gold Filigree Triangular Corner Frame
class IslamicCornerFramePainter extends CustomPainter {
  final Color goldColor;
  final bool isLeft;

  IslamicCornerFramePainter({required this.goldColor, required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final strokePaint = Paint()
      ..color = goldColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final thinPaint = Paint()
      ..color = goldColor.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    final fillPaint = Paint()
      ..color = goldColor.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    canvas.save();

    if (!isLeft) {
      // Flip horizontally for right corner
      canvas.translate(w, 0);
      canvas.scale(-1, 1);
    }

    // Outer triangular bracket path
    final outerPath = Path();
    outerPath.moveTo(0, 0);
    outerPath.lineTo(w, 0);
    outerPath.quadraticBezierTo(w * 0.45, h * 0.45, 0, h);
    outerPath.close();

    canvas.drawPath(outerPath, fillPaint);
    canvas.drawPath(outerPath, strokePaint);

    // Inner parallel frame border line
    final innerFramePath = Path();
    innerFramePath.moveTo(4, 4);
    innerFramePath.lineTo(w - 8, 4);
    innerFramePath.quadraticBezierTo(w * 0.42, h * 0.42, 4, h - 8);
    innerFramePath.close();
    canvas.drawPath(innerFramePath, thinPaint);

    // Arabesque Filigree Loops & Concentric Arcs inside
    final arc1 = Path();
    arc1.moveTo(14, 4);
    arc1.quadraticBezierTo(w * 0.35, h * 0.28, 4, h * 0.65);
    canvas.drawPath(arc1, thinPaint);

    final arc2 = Path();
    arc2.moveTo(26, 4);
    arc2.quadraticBezierTo(w * 0.28, h * 0.22, 4, h * 0.45);
    canvas.drawPath(arc2, thinPaint);

    // Center Floral / Star Rosette motif in the corner
    final centerOffset = Offset(w * 0.26, h * 0.26);
    _drawRosetteMotif(canvas, centerOffset, 9.0, goldColor);

    // Leaf/vine flourishes radiating along the edges
    final vinePath1 = Path();
    vinePath1.moveTo(w * 0.5, 4);
    vinePath1.cubicTo(w * 0.6, 12, w * 0.7, 8, w * 0.85, 4);
    canvas.drawPath(vinePath1, thinPaint);

    final vinePath2 = Path();
    vinePath2.moveTo(4, h * 0.5);
    vinePath2.cubicTo(12, h * 0.6, 8, h * 0.7, 4, h * 0.85);
    canvas.drawPath(vinePath2, thinPaint);

    canvas.restore();
  }

  void _drawRosetteMotif(Canvas canvas, Offset center, double radius, Color c) {
    final p = Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const points = 8;
    for (int i = 0; i < points; i++) {
      final angle = (i * 2 * math.pi) / points;
      final offset = Offset(
        center.dx + (radius * 0.5) * math.cos(angle),
        center.dy + (radius * 0.5) * math.sin(angle),
      );
      canvas.drawCircle(offset, radius * 0.5, p);
    }
    canvas.drawCircle(
      center,
      radius * 0.3,
      Paint()
        ..color = c
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// CustomPainter for Islamic Rosette Medallion (Side Ornament for Bismillah)
class IslamicRosetteOrnamentPainter extends CustomPainter {
  final Color color;

  IslamicRosetteOrnamentPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    // Draw 8-lobed floral rosette petals
    const points = 8;
    for (int i = 0; i < points; i++) {
      final angle = (i * 2 * math.pi) / points;
      final petalCenter = Offset(
        center.dx + (radius * 0.45) * math.cos(angle),
        center.dy + (radius * 0.45) * math.sin(angle),
      );
      canvas.drawCircle(petalCenter, radius * 0.45, fillPaint);
      canvas.drawCircle(petalCenter, radius * 0.45, strokePaint);
    }

    // Outer 8-pointed star frame
    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final r = (i % 2 == 0) ? radius * 0.95 : radius * 0.65;
      final angle = (i * math.pi) / points;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, strokePaint);

    // Center dot
    canvas.drawCircle(
      center,
      radius * 0.25,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void _showRequireLoginModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bookmark_add_rounded,
                color: AppColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Silakan Masuk Terlebih Dahulu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Untuk menandai bacaan Al-Qur\'an dan menyimpan progres ibadah Anda secara permanen, silakan masuk ke akun Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Masuk ke Akun',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Nanti Saja',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    },
  );
}
