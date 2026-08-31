import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/modern_snack_bar.dart';
import '../../../data/services/location_service.dart';
import '../../../providers/prayer_provider.dart';

class MandatoryLocationSelectorSheet extends StatefulWidget {
  const MandatoryLocationSelectorSheet({super.key});

  @override
  State<MandatoryLocationSelectorSheet> createState() =>
      _MandatoryLocationSelectorSheetState();
}

class _MandatoryLocationSelectorSheetState
    extends State<MandatoryLocationSelectorSheet> {
  final TextEditingController _searchController = TextEditingController();
  bool _isDetectingGps = false;

  final List<String> _popularCities = [
    'Jakarta',
    'Surabaya',
    'Bandung',
    'Medan',
    'Semarang',
    'Makassar',
    'Palembang',
    'Tangerang',
    'Tangerang Selatan',
    'Depok',
    'Bekasi',
    'Bogor',
    'Yogyakarta',
    'Surakarta',
    'Malang',
    'Denpasar',
    'Banda Aceh',
    'Padang',
    'Pekanbaru',
    'Batam',
    'Jambi',
    'Bengkulu',
    'Bandar Lampung',
    'Pangkalpinang',
    'Tanjungpinang',
    'Serang',
    'Cirebon',
    'Tasikmalaya',
    'Sukabumi',
    'Garut',
    'Ciamis',
    'Cimahi',
    'Purwokerto',
    'Cilacap',
    'Banyumas',
    'Magelang',
    'Pekalongan',
    'Tegal',
    'Kudus',
    'Pati',
    'Jepara',
    'Demak',
    'Kendal',
    'Brebes',
    'Salatiga',
    'Blitar',
    'Kediri',
    'Madiun',
    'Mojokerto',
    'Pasuruan',
    'Probolinggo',
    'Banyuwangi',
    'Jember',
    'Sidoarjo',
    'Gresik',
    'Tuban',
    'Lamongan',
    'Pontianak',
    'Banjarmasin',
    'Banjarbaru',
    'Samarinda',
    'Balikpapan',
    'Tarakan',
    'Palangkaraya',
    'Manado',
    'Palu',
    'Kendari',
    'Gorontalo',
    'Mataram',
    'Kupang',
    'Ambon',
    'Ternate',
    'Jayapura',
    'Sorong',
    'Merauke',
    'Timika',
    'Makkah',
    'Madinah',
  ];

  List<String> _filteredCities = [];

  @override
  void initState() {
    super.initState();
    _filteredCities = List.from(_popularCities);
  }

  void _filterCities(String query) {
    final cleanQuery = query.trim();
    setState(() {
      if (cleanQuery.isEmpty) {
        _filteredCities = List.from(_popularCities);
      } else {
        final matches = _popularCities
            .where((city) =>
                city.toLowerCase().contains(cleanQuery.toLowerCase()))
            .toList();

        final exactExists =
            matches.any((c) => c.toLowerCase() == cleanQuery.toLowerCase());
        if (!exactExists) {
          _filteredCities = [cleanQuery, ...matches];
        } else {
          _filteredCities = matches;
        }
      }
    });
  }

  Future<void> _markLocationAsSet() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_initial_location_set', true);
  }

  void _detectGpsLocation() async {
    setState(() => _isDetectingGps = true);

    ModernSnackBar.show(
      context,
      title: 'Mendeteksi GPS',
      message: 'Mendapatkan lokasi presisi dari perangkat...',
      type: SnackBarType.info,
    );

    try {
      final prayerProv = Provider.of<PrayerProvider>(context, listen: false);
      final detectedCity = await prayerProv.detectAndLoadGpsLocation();

      await _markLocationAsSet();

      if (!mounted) return;
      Navigator.pop(context);

      ModernSnackBar.show(
        context,
        title: 'Lokasi Terdeteksi',
        message: 'Jadwal sholat & adzan otomatis disesuaikan untuk $detectedCity',
        type: SnackBarType.success,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDetectingGps = false);
      if (e is GpsDisabledException || e.toString().contains('GPS')) {
        LocationService.showGpsPromptDialog(context);
      } else {
        ModernSnackBar.show(
          context,
          title: 'Gagal Mendeteksi Lokasi',
          message: e.toString(),
          type: SnackBarType.error,
        );
      }
    }
  }

  void _selectCity(String cityName) async {
    final cleanCity = cityName.trim();
    if (cleanCity.isEmpty) return;

    final prayerProv = Provider.of<PrayerProvider>(context, listen: false);
    await prayerProv.loadPrayerTimes(city: cleanCity);

    await _markLocationAsSet();

    if (!mounted) return;
    Navigator.pop(context);

    ModernSnackBar.show(
      context,
      title: 'Lokasi Ditetapkan',
      message: 'Jadwal sholat & adzan diperbarui untuk $cleanCity',
      type: SnackBarType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim();
    final showCustomCityOption = query.isNotEmpty &&
        !_filteredCities.any((c) => c.toLowerCase() == query.toLowerCase());

    return PopScope(
      canPop: false,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          top: 24,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mandatory Indicator Badge Header
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primaryMedium),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on_rounded, size: 16, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'Langkah Wajib Pertama Kali',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Header Title & Instruction
            const Text(
              'Pilih Lokasi Terkini Anda',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Agar jadwal sholat 5 waktu & pengingat adzan berjalan presisi di perangkat Anda, mohon tentukan lokasi domisili Anda.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 20),

            // GPS Auto Detect Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isDetectingGps ? null : _detectGpsLocation,
                icon: _isDetectingGps
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(Icons.my_location_rounded, size: 20),
                label: Text(
                  _isDetectingGps
                      ? 'Mendeteksi GPS...'
                      : 'Deteksi Lokasi Otomatis (GPS)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            const Row(
              children: [
                Expanded(child: Divider(color: AppColors.cardBorder)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Atau Pilih / Cari Nama Kota',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ),
                Expanded(child: Divider(color: AppColors.cardBorder)),
              ],
            ),

            const SizedBox(height: 14),

            // Search Field Input
            TextField(
              controller: _searchController,
              onChanged: _filterCities,
              decoration: InputDecoration(
                hintText: 'Ketik nama kota di Indonesia...',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.primary, size: 22),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _filterCities('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.background,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Custom Entered City Option if not in list
            if (showCustomCityOption) ...[
              GestureDetector(
                onTap: () => _selectCity(query),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_location_alt_rounded,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Gunakan Kota "$query"',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            const Text(
              'Daftar Kota Populer',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),

            // Cities List
            Expanded(
              child: ListView.separated(
                itemCount: _filteredCities.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppColors.cardBorder),
                itemBuilder: (context, index) {
                  final city = _filteredCities[index];

                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    leading: const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    title: Text(
                      city,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: AppColors.primary, size: 20),
                    onTap: () => _selectCity(city),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
