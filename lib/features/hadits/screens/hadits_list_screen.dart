import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_back_button.dart';
import '../../../core/widgets/shimmer_skeleton.dart';
import '../../../core/widgets/islamic_empty_state.dart';
import '../../../core/router/smooth_page_route.dart';
import '../../../data/models/hadits_model.dart';
import '../../../providers/hadits_provider.dart';
import '../../quran/screens/quran_list_screen.dart';
import 'hadits_detail_screen.dart';

class HaditsListScreen extends StatefulWidget {
  const HaditsListScreen({super.key});

  @override
  State<HaditsListScreen> createState() => _HaditsListScreenState();
}

class _HaditsListScreenState extends State<HaditsListScreen> {
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
            image: AssetImage('assets/images/bgDetail.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Consumer<HaditsProvider>(
            builder: (context, haditsProv, child) {
              final count = haditsProv.totalHaditsCount;
              final filteredList = haditsProv.haditsList;

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

                  // Top Header Component (Emblem Badge + Title + Subtitle)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // 1. Golden Islamic Emblem Badge with Arabic Calligraphy
                        const IslamicStarBadge(
                          arabicText: 'الحديث',
                          size: 68,
                        ),

                        const SizedBox(height: 10),

                        // 2. Main Title "Hadits Shahih"
                        Text(
                          'Hadits Shahih',
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
                          count > 0
                              ? 'Total $count Hadits Pilihan Tersedia'
                              : 'Kumpulan Sabda & Sunnah Rasulullah SAW',
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
                  _buildSearchBar(context, haditsProv),

                  // Kitab/Periwayat Selector Bar
                  _buildBookSelectorBar(context, haditsProv),

                  // Category Filter Chips Bar
                  _buildFilterChipsBar(context, haditsProv),

                  const SizedBox(height: 4),

                  // Hadits Cards List
                  Expanded(
                    child: haditsProv.isLoading
                        ? _buildHaditsSkeletonLoader()
                        : filteredList.isEmpty
                            ? IslamicEmptyState(
                                title: 'Hadits Tidak Ditemukan',
                                message: _searchController.text.isNotEmpty
                                    ? 'Tidak ada hadits yang cocok dengan kata kunci "${_searchController.text}".'
                                    : 'Belum ada hadits untuk kategori "${haditsProv.selectedCategory}".',
                                actionLabel: 'Reset Pencarian',
                                onActionPressed: () {
                                  _searchController.clear();
                                  haditsProv.searchHadits('');
                                  haditsProv.setCategory('Semua');
                                  setState(() {});
                                },
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(top: 4, bottom: 24),
                                itemCount: filteredList.length,
                                itemBuilder: (context, index) {
                                  final hadits = filteredList[index];
                                  return _buildHaditsCard(context, hadits, index);
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
  Widget _buildSearchBar(BuildContext context, HaditsProvider haditsProv) {
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
                hintText: 'Cari judul, periwayat, atau isi hadits...',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (val) {
                haditsProv.searchHadits(val);
                setState(() {});
              },
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                haditsProv.searchHadits('');
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

  /// Kitab/Periwayat Selector Bar (Bukhari, Muslim, Tirmidzi, etc.)
  Widget _buildBookSelectorBar(BuildContext context, HaditsProvider haditsProv) {
    final books = [
      {'slug': 'bukhari', 'name': 'Bukhari'},
      {'slug': 'muslim', 'name': 'Muslim'},
      {'slug': 'tirmidzi', 'name': 'Tirmidzi'},
      {'slug': 'abudawud', 'name': 'Abu Daud'},
      {'slug': 'nasai', 'name': 'Nasai'},
      {'slug': 'ibnmajah', 'name': 'Ibnu Majah'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: books.map((b) {
          final isSelected = haditsProv.selectedBook == b['slug'];
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(
                b['name']!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF063D2E),
                ),
              ),
              selected: isSelected,
              selectedColor: const Color(0xFF059669),
              backgroundColor: Colors.white,
              elevation: isSelected ? 2 : 0,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF059669) : const Color(0xFFCBD5E1),
                ),
              ),
              onSelected: (selected) {
                if (selected && haditsProv.selectedBook != b['slug']) {
                  haditsProv.loadHadits(book: b['slug']!);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Category Filter Chips Bar matching Al-Qur'an screen
  Widget _buildFilterChipsBar(BuildContext context, HaditsProvider haditsProv) {
    final categories = haditsProv.categories;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          ...categories.map((cat) {
            final isSelected = haditsProv.selectedCategory == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => haditsProv.setCategory(cat),
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

  /// Single Hadits Card Widget matching Al-Qur'an & Murottal card styling
  Widget _buildHaditsCard(BuildContext context, HaditsModel hadits, int index) {
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
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          SmoothPageRoute.navigate(
            context,
            HaditsDetailScreen(hadits: hadits),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Header Row (Star Emblem Badge with Number, Periwayat Badge, Category Chip)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IslamicStarBadge(
                        arabicText: '${index + 1}',
                        size: 40,
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${hadits.book} No. ${hadits.number}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (hadits.category.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        hadits.category,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Hadits Title
              Text(
                hadits.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF063D2E),
                ),
              ),

              const SizedBox(height: 10),

              // Arabic Text Preview
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  hadits.arab,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.amiri(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                    height: 1.9,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Indonesian Translation Preview
              Text(
                '"${hadits.idTranslation}"',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 14),

              // Card Footer Row (Read More indicator, Share & Copy action icons)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 15,
                        color: Color(0xFF059669),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Baca Selengkapnya',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
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
                          final shareText = '${hadits.title} (${hadits.book} No. ${hadits.number})\n\n${hadits.arab}\n\n"${hadits.idTranslation}"';
                          Share.share(shareText, subject: hadits.title);
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
                              text: '${hadits.title} (${hadits.book} No. ${hadits.number})\n\n${hadits.arab}\n\n${hadits.idTranslation}',
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Teks hadits berhasil disalin!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHaditsSkeletonLoader() {
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShimmerSkeletonBox(width: 140, height: 20, borderRadius: 6),
                  ShimmerSkeletonBox(width: 60, height: 20, borderRadius: 6),
                ],
              ),
              SizedBox(height: 12),
              ShimmerSkeletonBox(width: 180, height: 18, borderRadius: 4),
              SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ShimmerSkeletonBox(width: 220, height: 26, borderRadius: 4),
              ),
              SizedBox(height: 10),
              ShimmerSkeletonBox(width: double.infinity, height: 14, borderRadius: 4),
            ],
          ),
        );
      },
    );
  }
}
