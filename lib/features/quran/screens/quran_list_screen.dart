import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_back_button.dart';
import '../../../core/widgets/shimmer_skeleton.dart';
import '../../../core/widgets/islamic_empty_state.dart';
import '../../../core/router/smooth_page_route.dart';
import '../../../data/models/surah_model.dart';
import '../../../data/services/firebase_service.dart';
import '../../../providers/quran_provider.dart';
import '../../onboarding/screens/onboarding_screen.dart';
import '../../main_navigation_screen.dart';
import 'quran_detail_screen.dart';

class QuranListScreen extends StatefulWidget {
  const QuranListScreen({super.key});

  @override
  State<QuranListScreen> createState() => _QuranListScreenState();
}

class _QuranListScreenState extends State<QuranListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bgAlquran.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Consumer<QuranProvider>(
            builder: (context, quranProv, child) {
              final isAudioActive = quranProv.isPlayingAudio ||
                  quranProv.isPlayingFullSurah ||
                  quranProv.playingAyatNumber != null;

              return Stack(
                children: [
                  Column(
                    children: [
                      // Top Action Bar (Back Button)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Row(
                          children: const [
                            GlassBackButton(),
                          ],
                        ),
                      ),

                      // Top Header Component (Emblem Badge + Al-Qur'an Title + Subtitle)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            // 1. Golden Islamic Emblem Badge with Arabic Calligraphy
                            const IslamicStarBadge(
                              arabicText: 'القرآن',
                              size: 68,
                            ),

                            const SizedBox(height: 10),

                            // 2. Main Title "Al-Qur'an"
                            Text(
                              'Al-Qur\'an',
                              style: GoogleFonts.lora(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF063D2E),
                                letterSpacing: 0.5,
                              ),
                            ),

                            const SizedBox(height: 4),

                            // 3. Subtitle "Firman Allah sebagai petunjuk hidup"
                            const Text(
                              'Firman Allah sebagai petunjuk hidup',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF2C5E50),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // 1. Search Bar at Top
                      _buildSearchBar(context, quranProv),

                  // 2. Horizontal Filter Pills Bar (Semua, Makkiyah, Madaniyah, Juz Dropdown)
                  _buildFilterChipsBar(context, quranProv),

                  const SizedBox(height: 6),

                  // 3. Surah List Cards
                  Expanded(
                    child: quranProv.isLoading
                        ? _buildQuranSkeletonLoader()
                        : quranProv.errorMessage.isNotEmpty && quranProv.surahList.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.wifi_off_rounded,
                                        size: 48,
                                        color: AppColors.textMuted,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        quranProv.errorMessage,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: () => quranProv.loadSurahs(),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF063D2E),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                        ),
                                        icon: const Icon(Icons.refresh_rounded, size: 18),
                                        label: const Text('Coba Lagi'),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : quranProv.surahList.isEmpty
                                ? IslamicEmptyState(
                                    title: 'Surah Tidak Ditemukan',
                                    message: _searchController.text.isNotEmpty
                                        ? 'Tidak ada surah yang cocok dengan kata kunci "${_searchController.text}".'
                                        : 'Belum ada surah untuk kategori "${quranProv.selectedCategory}".',
                                    actionLabel: 'Reset Pencarian',
                                    onActionPressed: () {
                                      _searchController.clear();
                                      quranProv.searchSurah('');
                                      quranProv.setCategoryFilter('Semua');
                                      setState(() {});
                                    },
                                  )
                                : ListView.builder(
                                    padding: EdgeInsets.only(
                                      top: 4,
                                      bottom: isAudioActive ? 90 : 24,
                                    ),
                                    itemCount: quranProv.surahList.length,
                                    itemBuilder: (context, index) {
                                      final surah = quranProv.surahList[index];
                                      return _buildSurahCard(context, surah, quranProv);
                                    },
                                  ),
                  ),
                ],
              ),

              // 4. Floating Bottom Audio Player Bar
              if (isAudioActive)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: _buildFloatingAudioPlayer(context, quranProv),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
  
  /// Top Search Bar matching reference layout
  Widget _buildSearchBar(BuildContext context, QuranProvider quranProv) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
              decoration: const InputDecoration(
                hintText: 'Cari surat atau nomor...',
                hintStyle: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (val) {
                quranProv.searchSurah(val);
              },
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                quranProv.searchSurah('');
                setState(() {});
              },
              child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
            )
          else
            const Icon(
              Icons.search_rounded,
              size: 20,
              color: Color(0xFF94A3B8),
            ),
        ],
      ),
    );
  }

  /// Horizontal Filter Pills Bar (Semua, Makkiyah, Madaniyah, Juz X ˅)
  Widget _buildFilterChipsBar(BuildContext context, QuranProvider quranProv) {
    final categories = ['Semua', 'Makkiyah', 'Madaniyah'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          ...categories.map((cat) {
            final isSelected = quranProv.selectedCategory == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => quranProv.setCategoryFilter(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF063D2E) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Single Surah Card Widget
  Widget _buildSurahCard(BuildContext context, SurahModel surah, QuranProvider quranProv) {
    final isBookmarked = quranProv.isBookmarked(surah.nomor);
    final isMakkiyah = surah.tempatTurun.toLowerCase().contains('mekah') ||
        surah.tempatTurun.toLowerCase().contains('mekan') ||
        surah.tempatTurun.toLowerCase().contains('makki');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          quranProv.loadSurahDetail(surah.nomor);
          SmoothPageRoute.navigate(
            context,
            QuranDetailScreen(surahNumber: surah.nomor),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // 1. Surah Number
              SizedBox(
                width: 24,
                child: Text(
                  '${surah.nomor}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // 2. 8-Pointed Golden Star Emblem Badge with Arabic Calligraphy
              IslamicStarBadge(arabicText: surah.nama, size: 46),
              const SizedBox(width: 12),

              // 3. Middle Info: Latin Name & Meaning + Type Badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surah.namaLatin,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF063D2E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            surah.arti,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isMakkiyah ? 'Makkiyah' : 'Madaniyah',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // 4. Right Info: Arabic Name & Verse Count
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    surah.nama,
                    style: GoogleFonts.amiri(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${surah.jumlahAyat} ayat',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),

              // 5. Bookmark Ribbon Outline / Filled Button
              GestureDetector(
                onTap: () async {
                  final isLoggedIn = await FirebaseService().isLoggedIn();
                  if (!isLoggedIn) {
                    if (context.mounted) _showRequireLoginModal(context);
                    return;
                  }
                  quranProv.toggleBookmark(surah.nomor);
                },
                child: Icon(
                  isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                  size: 22,
                  color: isBookmarked ? const Color(0xFF063D2E) : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Skeleton Shimmer Loader for Surah List
  Widget _buildQuranSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
          ),
          child: const Row(
            children: [
              // Surah Number placeholder
              ShimmerSkeletonBox(width: 20, height: 16, borderRadius: 4),
              SizedBox(width: 12),

              // Star Emblem placeholder
              ShimmerSkeletonBox(width: 44, height: 44, borderRadius: 22),
              SizedBox(width: 12),

              // Surah info (Latin name & meaning)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerSkeletonBox(width: 110, height: 16, borderRadius: 4),
                    SizedBox(height: 6),
                    ShimmerSkeletonBox(width: 140, height: 12, borderRadius: 4),
                  ],
                ),
              ),
              SizedBox(width: 8),

              // Arabic info (Arabic name & verse count)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ShimmerSkeletonBox(width: 60, height: 18, borderRadius: 4),
                  SizedBox(height: 4),
                  ShimmerSkeletonBox(width: 45, height: 11, borderRadius: 4),
                ],
              ),
              SizedBox(width: 10),

              // Bookmark icon placeholder
              ShimmerSkeletonBox(width: 20, height: 20, borderRadius: 4),
            ],
          ),
        );
      },
    );
  }

  /// Floating Mini Audio Player Widget
  Widget _buildFloatingAudioPlayer(BuildContext context, QuranProvider quranProv) {
    final currentSurahName = quranProv.currentSurah?.namaLatin ?? 'Al-Fatihah';
    final isPlaying = quranProv.isPlayingAudio;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryLight,
              image: const DecorationImage(
                image: NetworkImage('https://static.qurancdn.com/images/reciters/7/mishary-rashid-alafasy-profile.jpeg'),
                fit: BoxFit.cover,
              ),
              border: Border.all(color: AppColors.cardBorder, width: 1),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Mishary Rashid Alafasy',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  currentSurahName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              if (quranProv.currentSurah != null && quranProv.currentSurah!.audioFull.isNotEmpty) {
                final audioUrl = quranProv.currentSurah!.audioFull.values.first;
                quranProv.playFullSurahAudio(audioUrl);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pilih surah untuk memutar audio Murottal.')),
                );
              }
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFF063D2E),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.format_list_bulleted_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => quranProv.stopAudio(),
            child: const Icon(
              Icons.close_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

/// Custom 8-Pointed Star Badge (Rub el Hizb) with Dark Green Fill & Gold Frame
class IslamicStarBadge extends StatelessWidget {
  final String arabicText;
  final double size;

  const IslamicStarBadge({
    super.key,
    required this.arabicText,
    this.size = 46.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: IslamicStarPainter(
          borderColor: const Color(0xFFC59B27), // Gold accent border
          fillColor: const Color(0xFF063D2E),   // Dark Green fill
        ),
        child: Center(
          child: Container(
            width: size * 0.68,
            height: size * 0.68,
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                arabicText,
                textAlign: TextAlign.center,
                style: GoogleFonts.amiri(
                  fontSize: size * 0.35,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFF8FAFC),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// CustomPainter for 8-Pointed Rub el Hizb Islamic Star Frame
class IslamicStarPainter extends CustomPainter {
  final Color borderColor;
  final Color fillColor;

  IslamicStarPainter({
    required this.borderColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final innerRadius = radius * 0.88;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final innerBorderPaint = Paint()
      ..color = borderColor.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw inner green circle fill
    canvas.drawCircle(center, innerRadius, fillPaint);

    // Draw 8-pointed star frame (Rub el Hizb outer points)
    final path = Path();
    const points = 8;
    final outerR = radius - 0.5;
    final innerR = radius * 0.82;

    for (int i = 0; i < points * 2; i++) {
      final r = (i % 2 == 0) ? outerR : innerR;
      final angle = (i * math.pi) / points - (math.pi / 2);
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, borderPaint);

    // Draw inner decorative circle ring
    canvas.drawCircle(center, innerRadius * 0.92, innerBorderPaint);
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
