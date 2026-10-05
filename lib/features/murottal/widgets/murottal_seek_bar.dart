import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../models/position_data.dart';

class MurottalSeekBar extends StatelessWidget {
  final Stream<PositionData> positionDataStream;
  final ValueChanged<Duration> onSeek;

  const MurottalSeekBar({
    super.key,
    required this.positionDataStream,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PositionData>(
      stream: positionDataStream,
      builder: (context, snapshot) {
        final positionData = snapshot.data ??
            const PositionData(
              position: Duration.zero,
              bufferedPosition: Duration.zero,
              duration: Duration.zero,
            );

        return ProgressBar(
          progress: positionData.position,
          buffered: positionData.bufferedPosition,
          total: positionData.duration,
          onSeek: onSeek,
          progressBarColor: AppColors.accentGold,
          baseBarColor: Colors.white.withOpacity(0.18),
          bufferedBarColor: Colors.white.withOpacity(0.35),
          thumbColor: AppColors.accentGold,
          thumbGlowColor: AppColors.accentGold.withOpacity(0.3),
          thumbRadius: 6.0,
          barHeight: 4.0,
          timeLabelLocation: TimeLabelLocation.below,
          timeLabelTextStyle: GoogleFonts.plusJakartaSans(
            color: Colors.white.withOpacity(0.7),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          timeLabelPadding: 6.0,
        );
      },
    );
  }
}
