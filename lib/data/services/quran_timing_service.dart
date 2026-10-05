import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WordSegment {
  final int wordIndex; // 1-based word index in the verse
  final int startMs;   // Start offset in milliseconds relative to the verse audio
  final int endMs;     // End offset in milliseconds relative to the verse audio

  const WordSegment({
    required this.wordIndex,
    required this.startMs,
    required this.endMs,
  });

  Map<String, dynamic> toJson() => {
        'wordIndex': wordIndex,
        'startMs': startMs,
        'endMs': endMs,
      };

  factory WordSegment.fromJson(Map<String, dynamic> json) => WordSegment(
        wordIndex: json['wordIndex'] as int,
        startMs: json['startMs'] as int,
        endMs: json['endMs'] as int,
      );
}

class SurahTimingData {
  final int surahNumber;
  final Duration totalDuration;
  final Map<int, List<WordSegment>> verseSegments; // Key: ayatNumber (1-based)
  final Map<int, Duration> verseDurations;         // Key: ayatNumber

  const SurahTimingData({
    required this.surahNumber,
    required this.totalDuration,
    required this.verseSegments,
    required this.verseDurations,
  });

  Map<String, dynamic> toJson() => {
        'surahNumber': surahNumber,
        'totalDurationMs': totalDuration.inMilliseconds,
        'verseSegments': verseSegments.map(
          (k, v) => MapEntry(k.toString(), v.map((s) => s.toJson()).toList()),
        ),
        'verseDurations': verseDurations.map(
          (k, v) => MapEntry(k.toString(), v.inMilliseconds),
        ),
      };

  factory SurahTimingData.fromJson(Map<String, dynamic> json) {
    final surahNumber = json['surahNumber'] as int;
    final totalDurationMs = json['totalDurationMs'] as int? ?? 0;
    final rawSegments = json['verseSegments'] as Map<String, dynamic>? ?? {};
    final rawDurations = json['verseDurations'] as Map<String, dynamic>? ?? {};

    final verseSegments = <int, List<WordSegment>>{};
    rawSegments.forEach((k, v) {
      final ayatNum = int.tryParse(k);
      if (ayatNum != null && v is List) {
        verseSegments[ayatNum] = v
            .map((item) => WordSegment.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    });

    final verseDurations = <int, Duration>{};
    rawDurations.forEach((k, v) {
      final ayatNum = int.tryParse(k);
      if (ayatNum != null && v is int) {
        verseDurations[ayatNum] = Duration(milliseconds: v);
      }
    });

    return SurahTimingData(
      surahNumber: surahNumber,
      totalDuration: Duration(milliseconds: totalDurationMs),
      verseSegments: verseSegments,
      verseDurations: verseDurations,
    );
  }
}

class QuranTimingService {
  static final QuranTimingService _instance = QuranTimingService._internal();
  factory QuranTimingService() => _instance;
  QuranTimingService._internal();

  final http.Client _client = http.Client();
  final Map<String, SurahTimingData> _memoryCache = {};

  // Maps local Qari keys ('05', '06') to Quran.com chapter reciter IDs
  static const Map<String, int> _qariReciterMap = {
    '05': 7, // Mishari Rashid Alafasy
    '06': 7, // Yasser Al-Dosari
  };

  /// Fetches or retrieves cached word-by-word timing data & total surah duration
  Future<SurahTimingData?> fetchSurahTiming(
    int surahNumber, {
    String qariKey = '05',
  }) async {
    final cacheKey = '${surahNumber}_$qariKey';

    // 1. Check in-memory cache
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey];
    }

    // 2. Check local SharedPreferences persistent cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('quran_timing_$cacheKey');
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final data = SurahTimingData.fromJson(
          jsonDecode(cachedJson) as Map<String, dynamic>,
        );
        _memoryCache[cacheKey] = data;
        return data;
      }
    } catch (_) {}

    // 3. Fetch from Quran.com API v4
    try {
      final reciterId = _qariReciterMap[qariKey] ?? 7;
      final url = Uri.parse(
        'https://api.quran.com/api/v4/chapter_recitations/$reciterId/$surahNumber?segments=true',
      );

      final response = await _client.get(url).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final audioFile = body['audio_file'] as Map<String, dynamic>?;
        if (audioFile != null) {
          final timestamps = audioFile['timestamps'] as List<dynamic>? ?? [];

          final verseSegments = <int, List<WordSegment>>{};
          final verseDurations = <int, Duration>{};
          int maxTimestampTo = 0;

          for (final item in timestamps) {
            final verseKey = item['verse_key'] as String? ?? '';
            final parts = verseKey.split(':');
            final ayatNum = parts.length == 2 ? int.tryParse(parts[1]) : null;

            final timestampFrom = item['timestamp_from'] as int? ?? 0;
            final timestampTo = item['timestamp_to'] as int? ?? 0;
            final durationMs = item['duration'] as int? ?? (timestampTo - timestampFrom);

            if (timestampTo > maxTimestampTo) {
              maxTimestampTo = timestampTo;
            }

            if (ayatNum != null) {
              verseDurations[ayatNum] = Duration(milliseconds: durationMs);

              final rawSegments = item['segments'] as List<dynamic>? ?? [];
              final segments = <WordSegment>[];

              for (final seg in rawSegments) {
                if (seg is List && seg.length >= 3) {
                  final wordIdx = seg[0] as int;
                  final rawStart = seg[1] as int;
                  final rawEnd = seg[2] as int;

                  // Normalize start/end relative to the individual verse audio
                  final relStart = (rawStart - timestampFrom).clamp(0, durationMs);
                  final relEnd = (rawEnd - timestampFrom).clamp(0, durationMs);

                  segments.add(
                    WordSegment(
                      wordIndex: wordIdx,
                      startMs: relStart,
                      endMs: relEnd,
                    ),
                  );
                }
              }

              verseSegments[ayatNum] = segments;
            }
          }

          final surahTiming = SurahTimingData(
            surahNumber: surahNumber,
            totalDuration: Duration(milliseconds: maxTimestampTo),
            verseSegments: verseSegments,
            verseDurations: verseDurations,
          );

          // Save to memory and disk cache
          _memoryCache[cacheKey] = surahTiming;
          _saveToDisk(cacheKey, surahTiming);

          return surahTiming;
        }
      }
    } catch (e) {
      debugPrint('[QuranTimingService] Error fetching timing data: $e');
    }

    return null;
  }

  void _saveToDisk(String cacheKey, SurahTimingData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'quran_timing_$cacheKey',
        jsonEncode(data.toJson()),
      );
    } catch (_) {}
  }

  /// Calculates the 1-based active word index for [ayatNumber] given the [positionMs].
  /// Accurately synchronized with Qari recitation using duration-scaling and syllable-weighting.
  int getActiveWordIndex({
    required SurahTimingData? timingData,
    required int ayatNumber,
    required int positionMs,
    required List<String> words,
    required Duration verseTotalDuration,
  }) {
    final totalWords = words.length;
    if (totalWords <= 0) return 1;

    // 1. Precise Segment-Based Synchronization (Quran.com API Timestamps with Dynamic Audio Scaling)
    if (timingData != null && timingData.verseSegments.containsKey(ayatNumber)) {
      final segments = timingData.verseSegments[ayatNumber]!;
      if (segments.isNotEmpty) {
        final segDuration = timingData.verseDurations[ayatNumber]?.inMilliseconds ??
            (segments.last.endMs > 0 ? segments.last.endMs : 5000);
        final actualDuration = verseTotalDuration.inMilliseconds > 0
            ? verseTotalDuration.inMilliseconds
            : segDuration;

        final double scaleRatio = segDuration > 0
            ? (actualDuration / segDuration)
            : 1.0;

        for (int i = 0; i < segments.length; i++) {
          final seg = segments[i];
          final startScaled = (seg.startMs * scaleRatio).round();
          final endScaled = (seg.endMs * scaleRatio).round();

          if (positionMs >= startScaled && positionMs <= endScaled) {
            if (segments.length == totalWords) {
              return (i + 1).clamp(1, totalWords);
            }
            final mappedWordIdx = ((i / segments.length) * totalWords).floor() + 1;
            return mappedWordIdx.clamp(1, totalWords);
          }
        }

        // Past last segment
        if (positionMs >= (segments.last.startMs * scaleRatio).round()) {
          return totalWords;
        }

        // Intermediate silence or minor gap: match closest previous segment
        for (int i = segments.length - 1; i >= 0; i--) {
          if (positionMs >= (segments[i].startMs * scaleRatio).round()) {
            final mapped = ((i / segments.length) * totalWords).floor() + 1;
            return mapped.clamp(1, totalWords);
          }
        }
        return 1;
      }
    }

    // 2. Tajwid & Syllable-Weighted Fallback (Accounts for Madd, Shaddah, and Long Vowels)
    final totalMs = verseTotalDuration.inMilliseconds > 0
        ? verseTotalDuration.inMilliseconds
        : (totalWords * 900);

    final weights = <double>[];
    double totalWeight = 0;

    for (final word in words) {
      double weight = word.length.toDouble();
      for (final char in word.runes) {
        final c = String.fromCharCode(char);
        if (c == 'ٓ' || c == '~' || c == 'ٰ' || c == 'ۥ' || c == 'ۦ') {
          weight += 4.0; // Madd / Long pronunciation
        } else if (c == 'ّ') {
          weight += 2.0; // Shaddah / Double consonant
        } else if (c == 'ا' || c == 'و' || c == 'ي') {
          weight += 1.5; // Huruf Illat / Madd Asli
        }
      }
      if (weight < 2.0) weight = 2.0;
      weights.add(weight);
      totalWeight += weight;
    }

    if (totalWeight <= 0) return 1;

    final effectivePos = (positionMs - 120).clamp(0, totalMs);
    final currentFraction = (effectivePos / totalMs).clamp(0.0, 0.999);
    final targetWeightProgress = currentFraction * totalWeight;

    double accumulatedWeight = 0;
    for (int i = 0; i < weights.length; i++) {
      accumulatedWeight += weights[i];
      if (targetWeightProgress <= accumulatedWeight || i == weights.length - 1) {
        return (i + 1).clamp(1, totalWords);
      }
    }

    return 1;
  }

  /// Helper to format duration to mm:ss or hh:mm:ss
  static String formatDuration(Duration duration) {
    if (duration == Duration.zero) return '00:00';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}
