import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/ayat_model.dart';
import '../../../data/models/surah_model.dart';

class AyatListPanel extends StatefulWidget {
  final List<AyatModel> ayatList;
  final SurahModel? surah;
  final int activeIndex;
  final ValueChanged<int> onSelectAyat;

  const AyatListPanel({
    super.key,
    required this.ayatList,
    required this.surah,
    required this.activeIndex,
    required this.onSelectAyat,
  });

  @override
  State<AyatListPanel> createState() => _AyatListPanelState();
}

class _AyatListPanelState extends State<AyatListPanel> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  @override
  void initState() {
    super.initState();
    if (widget.activeIndex >= 0 && widget.activeIndex < widget.ayatList.length) {
      _scrollToActiveAyat();
    }
  }

  @override
  void didUpdateWidget(covariant AyatListPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeIndex != widget.activeIndex &&
        widget.activeIndex >= 0 &&
        widget.activeIndex < widget.ayatList.length) {
      _scrollToActiveAyat();
    }
  }

  void _scrollToActiveAyat() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _itemScrollController.isAttached) {
        _itemScrollController.scrollTo(
          index: widget.activeIndex,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOutCubic,
          alignment: 0.2, // position near top-third of viewport
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ayatList.isEmpty) {
      return Center(
        child: Text(
          'Daftar ayat belum tersedia',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Panel Header (Fixed Overflow with Flexible Layout)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.format_list_numbered_rounded,
                  color: AppColors.accentGold,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Daftar Ayat (${widget.ayatList.length})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (widget.activeIndex >= 0 &&
                  widget.activeIndex < widget.ayatList.length)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.accentGold.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.graphic_eq_rounded,
                        size: 12,
                        color: AppColors.accentGold,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Ayat ${widget.ayatList[widget.activeIndex].nomorAyat}',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.accentGold,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const Divider(color: Colors.white12, height: 1),

        // Scrollable List of Ayats
        Expanded(
          child: ScrollablePositionedList.builder(
            itemCount: widget.ayatList.length,
            itemScrollController: _itemScrollController,
            itemPositionsListener: _itemPositionsListener,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            itemBuilder: (context, index) {
              final ayat = widget.ayatList[index];
              final isActive = index == widget.activeIndex;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => widget.onSelectAyat(index),
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF134E44).withOpacity(0.85)
                            : Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive
                              ? AppColors.accentGold.withOpacity(0.6)
                              : Colors.white.withOpacity(0.06),
                          width: isActive ? 1.5 : 1.0,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: AppColors.accentGold.withOpacity(0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Ayat Number Badge
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive
                                  ? AppColors.accentGold
                                  : Colors.white.withOpacity(0.08),
                            ),
                            child: Center(
                              child: isActive
                                  ? const Icon(
                                      Icons.graphic_eq_rounded,
                                      size: 18,
                                      color: Color(0xFF063D2E),
                                    )
                                  : Text(
                                      '${ayat.nomorAyat}',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white.withOpacity(0.85),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Text Content Preview: Pure Arabic
                          Expanded(
                            child: Text(
                              ayat.teksArab,
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.amiri(
                                fontSize: 19,
                                height: 1.9,
                                color: isActive
                                    ? const Color(0xFFFFDF7A)
                                    : Colors.white.withOpacity(0.9),
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
