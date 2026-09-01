import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_back_button.dart';
import '../../../core/widgets/shimmer_skeleton.dart';
import '../../../core/widgets/islamic_empty_state.dart';
import '../../../core/router/smooth_page_route.dart';
import '../../../data/models/surah_model.dart';
import '../../../providers/quran_provider.dart';
import '../../quran/screens/quran_detail_screen.dart';
import '../../quran/screens/quran_list_screen.dart';
import '../../quran/widgets/audio_player_bar.dart';

class MurottalScreen extends StatefulWidget {
  const MurottalScreen({super.key});

  @override
  State<MurottalScreen> createState() => _MurottalScreenState();
}

class _MurottalScreenState extends State<MurottalScreen> {
  final List<Map<String, String>> _qariList = const [
    {'key': '05', 'name': 'Misyari Rasyid Al-Afasi'},
    {'key': '01', 'name': 'Abdullah Al-Juhany'},
    {'key': '02', 'name': 'Abdul Muhsin Al-Qasim'},
    {'key': '03', 'name': 'Abdurrahman as-Sudais'},
    {'key': '04', 'name': 'Ibrahim Al-Dossari'},
  ];

  String _selectedQari = '05';
  String _selectedCategory = 'Semua';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qariName = _qariList.firstWhere(
      (q) => q['key'] == _selectedQari,
      orElse: () => _qariList.first,
    )['name']!;

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

              final searchQuery = _searchController.text.trim().toLowerCase();

              final filteredSurah = quranProv.surahList.where((s) {
                // Category filter
                final isMakkiyah = s.tempatTurun.toLowerCase().contains('mekah') ||
                    s.tempatTurun.toLowerCase().contains('mekan') ||
                    s.tempatTurun.toLowerCase().contains('makki');

                if (_selectedCategory == 'Makkiyah' && !isMakkiyah) return false;
                if (_selectedCategory == 'Madaniyah' && isMakkiyah) return false;

                // Search query filter
                if (searchQuery.isNotEmpty) {
                  return quranProv.matchesSurahSearch(s, searchQuery);
                }

                return true;
              }).toList();

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

                      // Top Header Component (Emblem Badge + Murottal Title + Subtitle)
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

                            // 2. Main Title "Murottal Al-Qur'an"
                            Text(
                              'Murottal Al-Qur\'an',
                              style: GoogleFonts.lora(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF063D2E),
                                letterSpacing: 0.5,
                              ),
                            ),

                            const SizedBox(height: 4),

                            // 3. Subtitle "Dengarkan lantunan indah ayat suci Al-Qur'an"
                            const Text(
                              'Dengarkan lantunan indah ayat suci Al-Qur\'an',
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

                      const SizedBox(height: 12),

                      // Qari Selection Pill Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: InkWell(
                          onTap: () => _showQariSelectorModal(context),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF063D2E),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.record_voice_over_rounded,
                                        color: Colors.white,
                                        size: 15,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Qari Murottal',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFF94A3B8),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          qariName,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF063D2E),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Color(0xFF063D2E),
                                  size: 22,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Search Input Field Card
                      _buildSearchBar(context),

                      // Category Filter Chips Bar (Semua, Makkiyah, Madaniyah)
                      _buildFilterChipsBar(context),

                      const SizedBox(height: 4),

                      // Surah Audio List Cards
                      Expanded(
                        child: quranProv.isLoading
                            ? _buildMurottalSkeletonLoader()
                            : (quranProv.errorMessage.isNotEmpty ||
                                    (quranProv.surahList.isEmpty &&
                                        searchQuery.isEmpty &&
                                        _selectedCategory == 'Semua'))
                                ? IslamicEmptyState(
                                    title: 'Koneksi Internet Terputus',
                                    message:
                                        'Perangkat Anda harus terhubung ke jaringan internet untuk memuat dan mendengarkan Murottal Al-Qur\'an.',
                                    actionLabel: 'Coba Lagi',
                                    onActionPressed: () => quranProv.loadSurahs(),
                                  )
                                : filteredSurah.isEmpty
                                    ? IslamicEmptyState(
                                        title: 'Murottal Tidak Ditemukan',
                                        message: _searchController.text.isNotEmpty
                                            ? 'Tidak ada surah yang cocok dengan kata kunci "${_searchController.text}".'
                                            : 'Belum ada murottal untuk kategori "$_selectedCategory".',
                                        actionLabel: 'Reset Pencarian',
                                        onActionPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            _selectedCategory = 'Semua';
                                          });
                                        },
                                      )
                                    : ListView.builder(
                                    padding: EdgeInsets.only(
                                      top: 4,
                                      bottom: isAudioActive ? 90 : 24,
                                    ),
                                    itemCount: filteredSurah.length,
                                    itemBuilder: (context, index) {
                                      final surah = filteredSurah[index];
                                      return _buildSurahAudioCard(context, surah, quranProv);
                                    },
                                  ),
                      ),
                    ],
                  ),

                  // Floating Audio Player Bar at Bottom
                  if (isAudioActive)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 16,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const AudioPlayerBar(),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Search Bar matching Al-Qur'an screen
  Widget _buildSearchBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                hintText: 'Cari surah atau nomor...',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (val) {
                setState(() {});
              },
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
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

  /// Category Filter Chips Bar matching Al-Qur'an screen
  Widget _buildFilterChipsBar(BuildContext context) {
    final categories = ['Semua', 'Makkiyah', 'Madaniyah'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          ...categories.map((cat) {
            final isSelected = _selectedCategory == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = cat;
                  });
                },
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

  /// Single Surah Audio Card Widget matching Al-Qur'an list item design
  Widget _buildSurahAudioCard(
    BuildContext context,
    SurahModel surah,
    QuranProvider quranProv,
  ) {
    final isCurrentPlayingSurah = quranProv.currentSurah?.nomor == surah.nomor;
    final isAudioActive = isCurrentPlayingSurah &&
        quranProv.isPlayingFullSurah &&
        quranProv.isPlayingAudio;
    final isAudioBuffering = (quranProv.loadingSurahNumber == surah.nomor ||
            (isCurrentPlayingSurah && quranProv.isPlayingFullSurah)) &&
        quranProv.isAudioLoading;

    final isMakkiyah = surah.tempatTurun.toLowerCase().contains('mekah') ||
        surah.tempatTurun.toLowerCase().contains('mekan') ||
        surah.tempatTurun.toLowerCase().contains('makki');

    final audioUrl = surah.audioFull[_selectedQari] ?? surah.audioFull['05'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: isCurrentPlayingSurah ? const Color(0xFFECFDF5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentPlayingSurah ? const Color(0xFF059669) : const Color(0xFFF1F5F9),
          width: isCurrentPlayingSurah ? 1.5 : 1.2,
        ),
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
          if (quranProv.currentSurah?.nomor == surah.nomor &&
              quranProv.isPlayingFullSurah) {
            quranProv.playFullSurahAudio(
              audioUrl,
              surahNumber: surah.nomor,
            );
          } else {
            quranProv.loadSurahDetail(surah.nomor).then((_) {
              quranProv.playFullSurahAudio(
                audioUrl,
                surahNumber: surah.nomor,
              );
            });
          }
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isCurrentPlayingSurah ? const Color(0xFF059669) : const Color(0xFF334155),
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
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isCurrentPlayingSurah ? const Color(0xFF059669) : const Color(0xFF063D2E),
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

              // 5. Play / Pause Button
              GestureDetector(
                onTap: () {
                  if (quranProv.currentSurah?.nomor == surah.nomor &&
                      quranProv.isPlayingFullSurah) {
                    quranProv.playFullSurahAudio(
                      audioUrl,
                      surahNumber: surah.nomor,
                    );
                  } else {
                    quranProv.loadSurahDetail(surah.nomor).then((_) {
                      quranProv.playFullSurahAudio(
                        audioUrl,
                        surahNumber: surah.nomor,
                      );
                    });
                  }
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isAudioActive || isAudioBuffering
                        ? const Color(0xFF063D2E)
                        : const Color(0xFFECFDF5),
                    shape: BoxShape.circle,
                  ),
                  child: isAudioBuffering
                      ? const Padding(
                          padding: EdgeInsets.all(9),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          isAudioActive
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: isAudioActive
                              ? Colors.white
                              : const Color(0xFF063D2E),
                          size: 22,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQariSelectorModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pilih Qari Murottal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF063D2E),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                itemCount: _qariList.length,
                itemBuilder: (context, index) {
                  final qari = _qariList[index];
                  final isSelected = qari['key'] == _selectedQari;
                  return ListTile(
                    leading: Icon(
                      Icons.record_voice_over_rounded,
                      color: isSelected
                          ? const Color(0xFF063D2E)
                          : const Color(0xFF94A3B8),
                    ),
                    title: Text(
                      qari['name']!,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? const Color(0xFF063D2E)
                            : const Color(0xFF1E293B),
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: Color(0xFF063D2E),
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedQari = qari['key']!;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMurottalSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 7,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: const Row(
            children: [
              ShimmerSkeletonBox(width: 46, height: 46, borderRadius: 23),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerSkeletonBox(
                      width: 120,
                      height: 16,
                      borderRadius: 4,
                    ),
                    SizedBox(height: 6),
                    ShimmerSkeletonBox(width: 90, height: 12, borderRadius: 4),
                  ],
                ),
              ),
              SizedBox(width: 12),
              ShimmerSkeletonBox(width: 36, height: 36, borderRadius: 18),
            ],
          ),
        );
      },
    );
  }
}
