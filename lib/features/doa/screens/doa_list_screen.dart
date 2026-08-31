import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_back_button.dart';
import '../../../core/widgets/shimmer_skeleton.dart';
import '../../../core/widgets/islamic_empty_state.dart';
import '../../../data/models/doa_model.dart';
import '../../../providers/doa_provider.dart';
import '../../quran/screens/quran_list_screen.dart';

class DoaListScreen extends StatefulWidget {
  const DoaListScreen({super.key});

  @override
  State<DoaListScreen> createState() => _DoaListScreenState();
}

class _DoaListScreenState extends State<DoaListScreen> {
  String _selectedCategory = 'Semua';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'Semua',
    'Puasa',
    'Sholat',
    'Makan',
    'Rumah',
    'Perlindungan',
    'Harian',
  ];

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
            image: AssetImage('assets/images/bgDetail.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Consumer<DoaProvider>(
            builder: (context, doaProv, child) {
              final searchQuery = _searchController.text.trim().toLowerCase();

              final filteredList = doaProv.doaList.where((doa) {
                // Category Filter
                if (_selectedCategory != 'Semua') {
                  final lowerTitle = doa.judul.toLowerCase();
                  final lowerTerjemah = doa.terjemah.toLowerCase();
                  final lowerLatin = doa.latin.toLowerCase();

                  bool matchesCat = false;
                  switch (_selectedCategory) {
                    case 'Puasa':
                      matchesCat = lowerTitle.contains('puasa') ||
                          lowerTitle.contains('sahur') ||
                          lowerTitle.contains('lailatul') ||
                          lowerTerjemah.contains('puasa');
                      break;
                    case 'Sholat':
                      matchesCat = lowerTitle.contains('sholat') ||
                          lowerTitle.contains('shalat') ||
                          lowerTitle.contains('wudhu') ||
                          lowerTitle.contains('adzan') ||
                          lowerTitle.contains('istikharah') ||
                          lowerTitle.contains('dhuha');
                      break;
                    case 'Makan':
                      matchesCat = lowerTitle.contains('makan') || lowerTitle.contains('minum');
                      break;
                    case 'Rumah':
                      matchesCat = lowerTitle.contains('rumah') ||
                          lowerTitle.contains('kamar') ||
                          lowerTitle.contains('wc') ||
                          lowerTitle.contains('tidur') ||
                          lowerTitle.contains('cermin') ||
                          lowerTitle.contains('pakaian');
                      break;
                    case 'Perlindungan':
                      matchesCat = lowerTitle.contains('wabah') ||
                          lowerTitle.contains('sakit') ||
                          lowerTitle.contains('musibah') ||
                          lowerTitle.contains('penyakit') ||
                          lowerTitle.contains('lindung') ||
                          lowerTitle.contains('ampunan') ||
                          lowerTitle.contains('terhindar');
                      break;
                    default:
                      final catLower = _selectedCategory.toLowerCase();
                      matchesCat = lowerTitle.contains(catLower) ||
                          lowerTerjemah.contains(catLower) ||
                          lowerLatin.contains(catLower);
                  }
                  if (!matchesCat) return false;
                }

                // Search Query Filter
                if (searchQuery.isNotEmpty) {
                  return doa.judul.toLowerCase().contains(searchQuery) ||
                      doa.terjemah.toLowerCase().contains(searchQuery) ||
                      doa.latin.toLowerCase().contains(searchQuery);
                }

                return true;
              }).toList();

              return Column(
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

                  // Top Header Component (Title + Subtitle)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 36),
                        // Main Title "Doa Harian"
                        Text(
                          'Kumpulan Doa Harian',
                          style: GoogleFonts.lora(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF063D2E),
                            letterSpacing: 0.5,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // 3. Subtitle
                        Text(
                          'Total ${doaProv.totalDoaCount} Doa & Dzikir Pilihan Tersedia',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
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

                  // Search Bar
                  _buildSearchBar(context, doaProv),

                  // Category Filter Chips Bar
                  _buildFilterChipsBar(context),

                  const SizedBox(height: 4),

                  // Doa Cards List
                  Expanded(
                    child: doaProv.isLoading
                        ? _buildDoaSkeletonLoader()
                        : filteredList.isEmpty
                            ? IslamicEmptyState(
                                title: 'Doa Tidak Ditemukan',
                                message: _searchController.text.isNotEmpty
                                    ? 'Tidak ada doa yang cocok dengan kata kunci "${_searchController.text}".'
                                    : 'Belum ada doa untuk kategori "$_selectedCategory".',
                                actionLabel: 'Reset Pencarian',
                                onActionPressed: () {
                                  _searchController.clear();
                                  doaProv.searchDoa('');
                                  setState(() {
                                    _selectedCategory = 'Semua';
                                  });
                                },
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(top: 4, bottom: 24),
                                itemCount: filteredList.length,
                                itemBuilder: (context, index) {
                                  final doa = filteredList[index];
                                  return _buildDoaCard(context, doa, index);
                                },
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
  Widget _buildSearchBar(BuildContext context, DoaProvider doaProv) {
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
                hintText: 'Cari doa harian atau puasa...',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (val) {
                doaProv.searchDoa(val);
                setState(() {});
              },
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                doaProv.searchDoa('');
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          ..._categories.map((cat) {
            final isSelected = _selectedCategory == cat;
            final labelText = cat == 'Semua' ? 'Semua Doa' : 'Doa $cat';
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
                    labelText,
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

  /// Single Doa Card Widget matching Al-Qur'an & Murottal card styling
  Widget _buildDoaCard(BuildContext context, DoaModel doa, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Header Row (Star Emblem Badge with Number, Title, Action Buttons)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IslamicStarBadge(
                  arabicText: '${index + 1}',
                  size: 42,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    doa.judul,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF063D2E),
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                      icon: const Icon(
                        Icons.share_outlined,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                      onPressed: () {
                        final shareText = '${doa.judul}\n\n${doa.arab}\n\n${doa.latin}\n\nArtinya:\n"${doa.terjemah}"';
                        Share.share(shareText, subject: doa.judul);
                      },
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                      icon: const Icon(
                        Icons.copy_rounded,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(
                            text: '${doa.judul}\n\n${doa.arab}\n\n${doa.latin}\n\n${doa.terjemah}',
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Teks doa berhasil disalin!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Arabic Text
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                doa.arab,
                textAlign: TextAlign.right,
                style: GoogleFonts.amiri(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                  height: 2.0,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Latin Transliteration
            Text(
              doa.latin,
              style: const TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Color(0xFF059669),
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 6),

            // Indonesian Translation
            Text(
              doa.terjemah,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoaSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ShimmerSkeletonBox(width: 42, height: 42, borderRadius: 21),
                  SizedBox(width: 12),
                  Expanded(
                    child: ShimmerSkeletonBox(width: 160, height: 18, borderRadius: 4),
                  ),
                ],
              ),
              SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: ShimmerSkeletonBox(width: 220, height: 26, borderRadius: 4),
              ),
              SizedBox(height: 10),
              ShimmerSkeletonBox(width: 180, height: 14, borderRadius: 4),
              SizedBox(height: 6),
              ShimmerSkeletonBox(width: double.infinity, height: 14, borderRadius: 4),
            ],
          ),
        );
      },
    );
  }
}
