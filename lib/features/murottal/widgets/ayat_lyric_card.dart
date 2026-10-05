import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/ayat_model.dart';
import '../../../data/models/surah_model.dart';

class AyatLyricCard extends StatefulWidget {
  final List<AyatModel> ayatList;
  final AyatModel? currentAyat;
  final SurahModel? surah;
  final int currentAyatIndex;
  final int activeWordIndex;
  final bool isLoading;
  final ValueChanged<int> onSelectAyat;

  const AyatLyricCard({
    super.key,
    required this.ayatList,
    this.currentAyat,
    this.surah,
    required this.currentAyatIndex,
    this.activeWordIndex = 0,
    this.isLoading = false,
    required this.onSelectAyat,
  });

  @override
  State<AyatLyricCard> createState() => _AyatLyricCardState();
}

class _AyatLyricCardState extends State<AyatLyricCard> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  @override
  void initState() {
    super.initState();
    if (widget.currentAyatIndex >= 0 &&
        widget.currentAyatIndex < widget.ayatList.length) {
      _scrollToActiveAyat();
    }
  }

  @override
  void didUpdateWidget(covariant AyatLyricCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentAyatIndex != widget.currentAyatIndex &&
        widget.currentAyatIndex >= 0 &&
        widget.currentAyatIndex < widget.ayatList.length) {
      _scrollToActiveAyat();
    }
  }

  void _scrollToActiveAyat() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _itemScrollController.isAttached) {
        _itemScrollController.scrollTo(
          index: widget.currentAyatIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
          alignment: 0.22, // Keeps active line comfortably in the upper-third viewport
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.ayatList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2.8,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGold),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Memuat lantunan ayat...',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    if (widget.ayatList.isEmpty) {
      return Center(
        child: Text(
          'Pilih surah untuk mendengarkan Murottal',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
      );
    }

    // Spotify-Style Continuous Lyrics Scroll View
    return ScrollablePositionedList.builder(
      itemCount: widget.ayatList.length,
      itemScrollController: _itemScrollController,
      itemPositionsListener: _itemPositionsListener,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      itemBuilder: (context, index) {
        final ayat = widget.ayatList[index];
        final isActive = index == widget.currentAyatIndex;

        return Padding(
          padding: const EdgeInsets.only(bottom: 26),
          child: InkWell(
            onTap: () => widget.onSelectAyat(index),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: isActive ? 1.0 : 0.35,
              child: _buildAyatRow(ayat, isActive),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAyatRow(AyatModel ayat, bool isActive) {
    if (!isActive) {
      // Inactive verse (Spotify dimmed style)
      return Text(
        ayat.teksArab,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        style: GoogleFonts.amiri(
          fontSize: 23,
          height: 2.0,
          fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.9),
        ),
      );
    }

    // Active verse (Spotify prominent highlight style with optional word sync)
    final words = ayat.teksArab.trim().split(RegExp(r'\s+'));
    final hasWordSync = widget.activeWordIndex > 0 &&
        widget.activeWordIndex <= words.length;

    if (!hasWordSync) {
      return Text(
        ayat.teksArab,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        style: GoogleFonts.amiri(
          fontSize: 29,
          height: 2.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      );
    }

    // Word-by-word highlight inside the active verse
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Wrap(
        alignment: WrapAlignment.start,
        spacing: 8.0,
        runSpacing: 10.0,
        children: List.generate(words.length, (wordIdx) {
          final oneBasedIdx = wordIdx + 1;
          final isCurrentWord = (widget.activeWordIndex == oneBasedIdx);
          final isPassedWord = (widget.activeWordIndex > oneBasedIdx);

          return AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            style: GoogleFonts.amiri(
              fontSize: isCurrentWord ? 31 : 29,
              height: 2.0,
              fontWeight: FontWeight.bold,
              color: isCurrentWord
                  ? const Color(0xFFFFDF7A) // Spotify Luminous Gold for active word
                  : (isPassedWord
                      ? Colors.white
                      : Colors.white.withOpacity(0.85)),
              shadows: isCurrentWord
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFFD54F).withOpacity(0.65),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              words[wordIdx],
              textAlign: TextAlign.right,
            ),
          );
        }),
      ),
    );
  }
}
