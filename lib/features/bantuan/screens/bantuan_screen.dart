import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/modern_snack_bar.dart';
import '../../../core/widgets/glass_back_button.dart';
import '../../main_navigation_screen.dart';

class BantuanScreen extends StatefulWidget {
  const BantuanScreen({super.key});

  @override
  State<BantuanScreen> createState() => _BantuanScreenState();
}

class _BantuanScreenState extends State<BantuanScreen> {
  String _selectedCategory = 'semua';
  String _searchQuery = '';
  final Set<String> _expandedIds = {};
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _faqs = [
    {
      'id': '1',
      'category': 'sholat',
      'question': 'Bagaimana cara mengubah lokasi jadwal sholat?',
      'answer':
          'Anda dapat mengubah lokasi dengan menekan ikon lokasi di Beranda, atau masuk ke menu Profil > Pilih Wilayah Kota. Sistem juga mendukung deteksi GPS otomatis.',
    },
    {
      'id': '2',
      'category': 'sholat',
      'question': 'Mengapa suara Adzan tidak berbunyi saat waktu sholat?',
      'answer':
          'Pastikan notifikasi aplikasi telah diizinkan pada Pengaturan HP Anda, serta pastikan tombol notifikasi adzan pada halaman Jadwal Sholat dalam posisi aktif (berwarna hijau).',
    },
    {
      'id': '3',
      'category': 'sholat',
      'question': 'Berapa selisih waktu Imsak dengan Subuh?',
      'answer':
          'Jadwal Imsak diset sekitar 10 menit sebelum waktu Subuh sesuai perhitungan standar Kementerian Agama Republik Indonesia (Kemenag RI).',
    },
    {
      'id': '4',
      'category': 'puasa',
      'question': 'Bagaimana cara menandai riwayat puasa harian?',
      'answer':
          'Buka menu Kalender pada navigasi bawah aplikasi, lalu ketuk tanggal hari ini untuk mencatat dan menyimpan status puasa Anda.',
    },
    {
      'id': '5',
      'category': 'quran',
      'question': 'Bagaimana cara mencatat penanda bacaan Al-Qur\'an?',
      'answer':
          'Saat membaca Al-Qur\'an, tekan ikon penanda (bookmark) pada ayat yang sedang Anda baca. Persentase progres Khatam di Beranda dan Profil akan terupdate secara otomatis.',
    },
    {
      'id': '6',
      'category': 'fitur',
      'question': 'Bagaimana cara menggunakan fitur Tasbih Digital?',
      'answer':
          'Tekan menu Tasbih di Beranda untuk membuka modal zikir. Anda dapat menambah hitungan dengan ketukan layar dan menggunakan fitur getar otomatis.',
    },
    {
      'id': '7',
      'category': 'fitur',
      'question': 'Bagaimana cara menggunakan Kompas Arah Kiblat?',
      'answer':
          'Buka menu Kiblat dan berikan izin akses lokasi (GPS) pada perangkat Anda untuk menghitung sudut presisi Ka\'bah dari lokasi Anda berada.',
    },
  ];

  final List<Map<String, String>> _categories = [
    {'id': 'semua', 'name': 'Semua'},
    {'id': 'sholat', 'name': 'Sholat & Adzan'},
    {'id': 'puasa', 'name': 'Puasa & Kalender'},
    {'id': 'quran', 'name': 'Al-Qur\'an'},
    {'id': 'fitur', 'name': 'Fitur Lainnya'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'sholat':
        return Icons.access_time_filled_rounded;
      case 'puasa':
        return Icons.calendar_month_rounded;
      case 'quran':
        return Icons.menu_book_rounded;
      case 'fitur':
        return Icons.widgets_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredFaqs = _faqs.where((faq) {
      final matchesCategory =
          _selectedCategory == 'semua' || faq['category'] == _selectedCategory;
      final matchesSearch = faq['question']!
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          faq['answer']!.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leadingWidth: 60,
        leading: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: GlassBackButton(),
        ),
        centerTitle: true,
        title: const Column(
          children: [
            Text(
              'Pusat Bantuan & FAQ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Pertanyaan Umum & Panduan Aplikasi',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modern Search Bar
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 12,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Cari pertanyaan atau bantuan...',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Horizontal Category Selector Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat['id'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: InkWell(
                        onTap: () => setState(() => _selectedCategory = cat['id']!),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.cardBorder,
                            ),
                            boxShadow: isSelected
                                ? const [
                                    BoxShadow(
                                      color: Color(0x200F766E),
                                      blurRadius: 8,
                                      offset: Offset(0, 3),
                                    )
                                  ]
                                : null,
                          ),
                          child: Text(
                            cat['name']!,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Section Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daftar Pertanyaan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${filteredFaqs.length} Pertanyaan',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // FAQ Accordion Cards
            if (filteredFaqs.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMuted),
                    SizedBox(height: 12),
                    Text(
                      'Pertanyaan Tidak Ditemukan',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Coba kata kunci pencarian lain atau pilih kategori lain.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredFaqs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final faq = filteredFaqs[index];
                  final isExpanded = _expandedIds.contains(faq['id']);
                  final catIcon = _getCategoryIcon(faq['category']!);

                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isExpanded ? AppColors.primaryMedium : AppColors.cardBorder,
                        width: isExpanded ? 1.2 : 1.0,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        key: Key(faq['id']!),
                        initiallyExpanded: isExpanded,
                        onExpansionChanged: (expanded) {
                          setState(() {
                            if (expanded) {
                              _expandedIds.add(faq['id']!);
                            } else {
                              _expandedIds.remove(faq['id']!);
                            }
                          });
                        },
                        leading: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isExpanded ? AppColors.primary : AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            catIcon,
                            color: isExpanded ? Colors.white : AppColors.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          faq['question']!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            color: isExpanded ? AppColors.primary : AppColors.textPrimary,
                            height: 1.3,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Text(
                                faq['answer']!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 28),

            // Modern Hero Support Banner Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF134E4A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x25000000),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Masih Butuh Bantuan?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tim kami siap membantu kendala penggunaan aplikasi Anda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ModernSnackBar.show(
                        context,
                        title: 'Layanan Dukungan',
                        message: 'Email dukungan kami: support@ramadhan.app',
                        type: SnackBarType.info,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Hubungi Bantuan',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Copyright Footer
            const Center(
              child: Column(
                children: [
                  Text(
                    'Copyright © 2026 by Aldi Kurniawan',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'All Rights Reserved',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
