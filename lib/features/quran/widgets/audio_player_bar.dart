import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/quran_provider.dart';

class AudioPlayerBar extends StatefulWidget {
  const AudioPlayerBar({super.key});

  @override
  State<AudioPlayerBar> createState() => _AudioPlayerBarState();
}

class _AudioPlayerBarState extends State<AudioPlayerBar> {
  final List<Map<String, String>> _qariList = const [
    {'key': '05', 'name': 'Misyari Rasyid Al-Afasi'},
    {'key': '01', 'name': 'Abdullah Al-Juhany'},
    {'key': '02', 'name': 'Abdul Muhsin Al-Qasim'},
    {'key': '03', 'name': 'Abdurrahman as-Sudais'},
    {'key': '04', 'name': 'Ibrahim Al-Dossari'},
  ];

  String _selectedQari = '05';

  @override
  Widget build(BuildContext context) {
    return Consumer<QuranProvider>(
      builder: (context, quranProv, child) {
        final surah = quranProv.currentSurah;
        if (surah == null || (!quranProv.isPlayingAudio && quranProv.playingAyatNumber == null && !quranProv.isPlayingFullSurah)) {
          return const SizedBox.shrink();
        }

        final title = quranProv.isPlayingFullSurah
            ? '${surah.namaLatin} (Full Surah)'
            : quranProv.playingAyatNumber != null
                ? '${surah.namaLatin} : Ayat ${quranProv.playingAyatNumber}'
                : surah.namaLatin;

        final qariName = _qariList.firstWhere(
              (q) => q['key'] == _selectedQari,
              orElse: () => _qariList.first,
            )['name'] ??
            'Misyari Rasyid Al-Afasi';

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.primaryMedium, width: 1.5),
            boxShadow: AppColors.elevatedShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top title row & close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.headphones_rounded,
                            color: AppColors.primary, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            qariName,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Select Qari Button
                      IconButton(
                        icon: const Icon(Icons.mic_outlined,
                            color: AppColors.primary, size: 20),
                        onPressed: () => _showQariSelector(context),
                      ),
                      // Stop / Close Player
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: AppColors.textMuted, size: 20),
                        onPressed: () {
                          quranProv.stopAudio();
                        },
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Player Transport Control Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          quranProv.isPlayingFullSurah ? 'Full Surah' : 'Per Ayat',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Center Play/Pause button
                  GestureDetector(
                    onTap: () {
                      if (quranProv.isPlayingFullSurah) {
                        final audioUrl =
                            surah.audioFull[_selectedQari] ?? surah.audioFull['05'] ?? '';
                        quranProv.playFullSurahAudio(audioUrl);
                      } else if (quranProv.playingAyatNumber != null) {
                        final currentAyat = quranProv.currentAyatList.firstWhere(
                            (a) => a.nomorAyat == quranProv.playingAyatNumber);
                        final audioUrl =
                            currentAyat.audio[_selectedQari] ?? currentAyat.audio['05'] ?? '';
                        quranProv.playAyatAudio(
                            quranProv.playingAyatNumber!, audioUrl);
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: AppColors.softShadow,
                      ),
                      child: quranProv.isAudioLoading
                          ? const Padding(
                              padding: EdgeInsets.all(11),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              quranProv.isPlayingAudio
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                    ),
                  ),

                  const SizedBox(width: 40),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showQariSelector(BuildContext context) {
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
                      color: AppColors.textPrimary,
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
                      Icons.mic_rounded,
                      color: isSelected ? AppColors.primary : AppColors.textMuted,
                    ),
                    title: Text(
                      qari['name']!,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: AppColors.primary)
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
}
