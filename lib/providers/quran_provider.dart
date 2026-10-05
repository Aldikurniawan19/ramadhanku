import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/surah_model.dart';
import '../data/models/ayat_model.dart';
import '../data/services/quran_service.dart';
import '../data/services/quran_timing_service.dart';
import '../data/services/firebase_service.dart';
import '../features/murottal/models/position_data.dart';

enum MurottalRepeatMode {
  off,
  repeatSurah,
  repeatAyat,
}

class QuranProvider extends ChangeNotifier {
  final QuranService _quranService = QuranService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  static const List<Map<String, String>> qariList = [
    {'key': '05', 'name': 'Misyari Rasyid Al-Afasi'},
    {'key': '06', 'name': 'Yasser Al-Dosari'},
  ];

  List<SurahModel> _surahList = [];
  List<SurahModel> _filteredSurahList = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';

  String _selectedCategory = 'Semua';
  Set<int> _bookmarkedSurahs = {};

  // Surah Detail State
  SurahModel? _currentSurah;
  List<AyatModel> _currentAyatList = [];
  bool _isLoadingDetail = false;

  // Active Murottal Player State
  SurahModel? _playingSurah;
  List<AyatModel> _playingAyatList = [];
  int _currentAyatIndex = 0;
  int? _playingAyatNumber;
  bool _isPlayingFullSurah = false;
  bool _isPlayingAudio = false;
  bool _isAudioLoading = false;
  int? _loadingSurahNumber;

  String _selectedQari = '05';
  MurottalRepeatMode _repeatMode = MurottalRepeatMode.off;
  bool _autoNextSurah = true;

  // Word-by-Word Timing & Total Surah Duration State
  SurahTimingData? _currentSurahTiming;
  Duration _surahTotalDuration = Duration.zero;
  int _activeWordIndex = 1;

  // Last Read State
  String _lastReadSurahName = 'Surah Al-Fatihah';
  int _lastReadSurahNumber = 1;
  int _lastReadAyatNumber = 1;
  int _lastReadJuzNumber = 1;

  // Getters
  List<SurahModel> get surahList => _filteredSurahList;
  List<SurahModel> get allSurahs => _surahList;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;
  Set<int> get bookmarkedSurahs => _bookmarkedSurahs;

  SurahModel? get currentSurah => _currentSurah;
  List<AyatModel> get currentAyatList => _currentAyatList;
  bool get isLoadingDetail => _isLoadingDetail;

  SurahModel? get playingSurah => _playingSurah ?? _currentSurah;
  List<AyatModel> get playingAyatList => _playingAyatList;
  int get currentAyatIndex => _currentAyatIndex;
  int? get playingAyatNumber => _playingAyatNumber;
  bool get isPlayingFullSurah => _isPlayingFullSurah;
  bool get isPlayingAudio => _isPlayingAudio;
  bool get isAudioLoading => _isAudioLoading;
  int? get loadingSurahNumber => _loadingSurahNumber;

  String get selectedQari => _selectedQari;
  MurottalRepeatMode get repeatMode => _repeatMode;
  bool get autoNextSurah => _autoNextSurah;

  SurahTimingData? get currentSurahTiming => _currentSurahTiming;
  Duration get surahTotalDuration => calculateTotalSurahDuration();
  String get formattedSurahTotalDuration =>
      QuranTimingService.formatDuration(calculateTotalSurahDuration());
  int get activeWordIndex => _activeWordIndex;

  AyatModel? get currentPlayingAyat {
    if (_playingAyatList.isNotEmpty &&
        _currentAyatIndex >= 0 &&
        _currentAyatIndex < _playingAyatList.length) {
      return _playingAyatList[_currentAyatIndex];
    }
    return null;
  }

  String get currentQariName {
    return qariList.firstWhere(
      (q) => q['key'] == _selectedQari,
      orElse: () => qariList.first,
    )['name']!;
  }

  String get lastReadSurahName => _lastReadSurahName;
  int get lastReadSurahNumber => _lastReadSurahNumber;
  int get lastReadAyatNumber => _lastReadAyatNumber;
  int get lastReadJuzNumber => _lastReadJuzNumber;

  /// Gets the estimated/exact duration of a specific verse
  Duration getAyatDuration(int ayatIndex) {
    if (_currentSurahTiming != null &&
        _playingAyatList.isNotEmpty &&
        ayatIndex < _playingAyatList.length) {
      final ayatNum = _playingAyatList[ayatIndex].nomorAyat;
      if (_currentSurahTiming!.verseDurations.containsKey(ayatNum)) {
        return _currentSurahTiming!.verseDurations[ayatNum]!;
      }
    }
    return const Duration(seconds: 5);
  }

  /// Gets accumulated duration of all verses played before [targetIndex]
  Duration getAccumulatedDurationBefore(int targetIndex) {
    var accumulated = Duration.zero;
    for (int i = 0; i < targetIndex && i < _playingAyatList.length; i++) {
      accumulated += getAyatDuration(i);
    }
    return accumulated;
  }

  /// Calculates the full surah total duration
  Duration calculateTotalSurahDuration() {
    if (_currentSurahTiming != null &&
        _currentSurahTiming!.totalDuration > Duration.zero) {
      return _currentSurahTiming!.totalDuration;
    }
    if (_playingAyatList.isNotEmpty) {
      var total = Duration.zero;
      for (int i = 0; i < _playingAyatList.length; i++) {
        total += getAyatDuration(i);
      }
      if (total > Duration.zero) return total;
    }
    return _surahTotalDuration > Duration.zero
        ? _surahTotalDuration
        : const Duration(seconds: 45);
  }

  /// Full-Surah Level PositionData Stream for Spotify-style Progress Bar
  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _audioPlayer.positionStream,
        _audioPlayer.bufferedPositionStream,
        _audioPlayer.durationStream,
        (versePos, verseBuffered, verseDur) {
          final totalSurah = calculateTotalSurahDuration();
          final accumulated = getAccumulatedDurationBefore(_currentAyatIndex);

          final surahPosition = accumulated + versePos;
          final surahBuffered = accumulated + verseBuffered;

          final effectiveTotal = totalSurah > Duration.zero
              ? totalSurah
              : (accumulated + (verseDur ?? Duration.zero));

          return PositionData(
            position: surahPosition > effectiveTotal
                ? effectiveTotal
                : (surahPosition < Duration.zero ? Duration.zero : surahPosition),
            bufferedPosition: surahBuffered > effectiveTotal
                ? effectiveTotal
                : (surahBuffered < Duration.zero ? Duration.zero : surahBuffered),
            duration: effectiveTotal > Duration.zero
                ? effectiveTotal
                : const Duration(seconds: 1),
          );
        },
      );

  QuranProvider() {
    loadSurahs();
    reloadUserData();
    _loadSelectedQari();
    _initAudioListeners();
  }

  Future<void> _loadSelectedQari() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedQari = prefs.getString('murottal_selected_qari');
      if (savedQari != null && savedQari.isNotEmpty) {
        final isValid = qariList.any((q) => q['key'] == savedQari);
        _selectedQari = isValid ? savedQari : '05';
        if (!isValid) {
          await prefs.setString('murottal_selected_qari', '05');
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setSelectedQari(String key) async {
    if (_selectedQari == key) return;
    _selectedQari = key;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('murottal_selected_qari', key);
    } catch (_) {}

    // If audio is currently playing in playlist mode, recreate playlist with new Qari at current ayat
    if (_playingSurah != null &&
        _playingAyatList.isNotEmpty &&
        (_isPlayingAudio || _isPlayingFullSurah)) {
      final currentIndex = _currentAyatIndex;
      await playSurahAyatPlaylist(
        _playingSurah!.nomor,
        startAyatIndex: currentIndex,
      );
    }
  }

  Future<void> reloadUserData() async {
    final uid = await FirebaseService().getEffectiveUserId();
    final prefs = await SharedPreferences.getInstance();
    _lastReadSurahName =
        prefs.getString('quran_surah_name_$uid') ?? 'Surah Al-Fatihah';
    _lastReadSurahNumber = prefs.getInt('quran_surah_num_$uid') ?? 1;
    _lastReadAyatNumber = prefs.getInt('quran_ayat_num_$uid') ?? 1;
    _lastReadJuzNumber = prefs.getInt('quran_juz_num_$uid') ?? 1;
    final bookmarksList = prefs.getStringList('quran_bookmarks_$uid') ?? [];
    _bookmarkedSurahs =
        bookmarksList.map((e) => int.tryParse(e) ?? 0).where((n) => n > 0).toSet();
    notifyListeners();

    try {
      final cloudLastRead = await FirebaseService().getLastReadQuran();
      if (cloudLastRead != null) {
        final sName =
            cloudLastRead['surahName'] as String? ?? _lastReadSurahName;
        final sNum =
            cloudLastRead['surahNumber'] as int? ?? _lastReadSurahNumber;
        final aNum =
            cloudLastRead['ayatNumber'] as int? ?? _lastReadAyatNumber;
        final jNum = cloudLastRead['juzNumber'] as int? ?? _lastReadJuzNumber;

        _lastReadSurahName = sName;
        _lastReadSurahNumber = sNum;
        _lastReadAyatNumber = aNum;
        _lastReadJuzNumber = jNum;

        await prefs.setString('quran_surah_name_$uid', sName);
        await prefs.setInt('quran_surah_num_$uid', sNum);
        await prefs.setInt('quran_ayat_num_$uid', aNum);
        await prefs.setInt('quran_juz_num_$uid', jNum);
        notifyListeners();
      }
    } catch (_) {}
  }

  void toggleBookmark(int surahNumber) async {
    if (_bookmarkedSurahs.contains(surahNumber)) {
      _bookmarkedSurahs.remove(surahNumber);
    } else {
      _bookmarkedSurahs.add(surahNumber);
    }
    notifyListeners();

    final uid = await FirebaseService().getEffectiveUserId();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'quran_bookmarks_$uid',
      _bookmarkedSurahs.map((e) => e.toString()).toList(),
    );
  }

  bool isBookmarked(int surahNumber) {
    return _bookmarkedSurahs.contains(surahNumber);
  }

  void updateLastRead({
    required String surahName,
    required int surahNumber,
    required int ayatNumber,
    required int juzNumber,
  }) async {
    _lastReadSurahName = surahName;
    _lastReadSurahNumber = surahNumber;
    _lastReadAyatNumber = ayatNumber;
    _lastReadJuzNumber = juzNumber;
    notifyListeners();

    final uid = await FirebaseService().getEffectiveUserId();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('quran_surah_name_$uid', surahName);
    await prefs.setInt('quran_surah_num_$uid', surahNumber);
    await prefs.setInt('quran_ayat_num_$uid', ayatNumber);
    await prefs.setInt('quran_juz_num_$uid', juzNumber);

    await FirebaseService().saveLastReadQuran(
      surahName: surahName,
      surahNumber: surahNumber,
      ayatNumber: ayatNumber,
      juzNumber: juzNumber,
    );
  }

  void _initAudioListeners() {
    _audioPlayer.playerStateStream.listen((state) {
      _isPlayingAudio = state.playing;

      final isProcessing = state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;
      _isAudioLoading = isProcessing;

      if (!isProcessing && state.playing) {
        _loadingSurahNumber = null;
      }

      if (state.processingState == ProcessingState.completed) {
        _handlePlaybackCompleted();
      }
      notifyListeners();
    });

    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null &&
          _playingAyatList.isNotEmpty &&
          index < _playingAyatList.length) {
        _currentAyatIndex = index;
        _playingAyatNumber = _playingAyatList[index].nomorAyat;
        _activeWordIndex = 1;
        notifyListeners();
      }
    });

    // Real-time Word-by-Word Synchronization Listener
    _audioPlayer.positionStream.listen((pos) {
      if (_playingAyatList.isNotEmpty &&
          _currentAyatIndex >= 0 &&
          _currentAyatIndex < _playingAyatList.length) {
        final currentAyat = _playingAyatList[_currentAyatIndex];
        final words = currentAyat.teksArab.trim().split(RegExp(r'\s+'));
        final newWordIdx = QuranTimingService().getActiveWordIndex(
          timingData: _currentSurahTiming,
          ayatNumber: currentAyat.nomorAyat,
          positionMs: pos.inMilliseconds,
          words: words,
          verseTotalDuration: _audioPlayer.duration ?? Duration.zero,
        );

        if (_activeWordIndex != newWordIdx) {
          _activeWordIndex = newWordIdx;
          notifyListeners();
        }
      }
    });
  }

  void _handlePlaybackCompleted() {
    if (_repeatMode == MurottalRepeatMode.repeatSurah) {
      _audioPlayer.seek(Duration.zero, index: 0);
      _audioPlayer.play();
    } else if (_autoNextSurah && _playingSurah != null) {
      final nextSurahNum = _playingSurah!.nomor + 1;
      if (nextSurahNum <= 114) {
        playSurahAyatPlaylist(nextSurahNum, startAyatIndex: 0);
      } else {
        stopAudio();
      }
    } else {
      _isPlayingAudio = false;
      _isAudioLoading = false;
      _loadingSurahNumber = null;
      notifyListeners();
    }
  }

  Future<void> loadSurahs() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _surahList = await _quranService.fetchAllSurahs();
      _applyFilters();
    } catch (e) {
      _errorMessage = 'Gagal memuat daftar Surah: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCategoryFilter(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void searchSurah(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredSurahList = _surahList.where((s) {
      bool matchesSearch = matchesSurahSearch(s, _searchQuery);

      bool matchesCategory = true;
      if (_selectedCategory == 'Makkiyah') {
        final tt = s.tempatTurun.toLowerCase();
        matchesCategory =
            tt.contains('mekah') || tt.contains('mekan') || tt.contains('makki');
      } else if (_selectedCategory == 'Madaniyah') {
        final tt = s.tempatTurun.toLowerCase();
        matchesCategory =
            tt.contains('madinah') || tt.contains('madin') || tt.contains('madan');
      }

      return matchesSearch && matchesCategory;
    }).toList();
  }

  bool matchesSurahSearch(SurahModel surah, String rawQuery) {
    final query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) return true;

    final String surahNumStr = surah.nomor.toString();
    if (surahNumStr == query || surahNumStr.startsWith(query)) {
      return true;
    }

    String cleanQueryStr = query
        .replaceAll(RegExp(r"^(surah|surat|qs\.?)\s+"), "")
        .trim();
    if (cleanQueryStr.isEmpty) cleanQueryStr = query;

    if (surahNumStr == cleanQueryStr) return true;

    final String arti = surah.arti.toLowerCase();
    if (arti.contains(cleanQueryStr) || arti.contains(query)) {
      return true;
    }

    if (surah.nama.contains(cleanQueryStr) || surah.nama.contains(query)) {
      return true;
    }

    final String namaLatin = surah.namaLatin.toLowerCase();
    if (namaLatin.contains(cleanQueryStr) || namaLatin.contains(query)) {
      return true;
    }

    String cleanPunctuation(String text) {
      return text.replaceAll(RegExp(r"[^a-z0-9]"), "");
    }

    final cleanName = cleanPunctuation(namaLatin);
    final cleanQ = cleanPunctuation(cleanQueryStr);

    if (cleanQ.isNotEmpty &&
        (cleanName.contains(cleanQ) || cleanQ.contains(cleanName))) {
      return true;
    }

    String collapseDuplicates(String text) {
      final c = cleanPunctuation(text);
      if (c.isEmpty) return c;
      final sb = StringBuffer();
      for (int i = 0; i < c.length; i++) {
        if (i == 0 || c[i] != c[i - 1]) {
          sb.write(c[i]);
        }
      }
      return sb.toString();
    }

    final collapsedName = collapseDuplicates(namaLatin);
    final collapsedQ = collapseDuplicates(cleanQueryStr);

    if (collapsedQ.isNotEmpty &&
        (collapsedName.contains(collapsedQ) || collapsedQ.contains(collapsedName))) {
      return true;
    }

    String normalizePhonetics(String text) {
      String s = collapseDuplicates(text);
      s = s.replaceAll("ts", "t");
      s = s.replaceAll("th", "t");
      s = s.replaceAll("sy", "s");
      s = s.replaceAll("sh", "s");
      s = s.replaceAll("kh", "h");
      s = s.replaceAll("dz", "z");
      s = s.replaceAll("dh", "z");
      return s;
    }

    final normName = normalizePhonetics(namaLatin);
    final normQ = normalizePhonetics(cleanQueryStr);

    if (normQ.isNotEmpty &&
        (normName.contains(normQ) || normQ.contains(normName))) {
      return true;
    }

    return false;
  }

  Future<void> loadSurahDetail(int surahNumber) async {
    final matches = _surahList.where((s) => s.nomor == surahNumber);
    _currentSurah = matches.isNotEmpty ? matches.first : null;
    _currentAyatList = [];
    _isLoadingDetail = true;
    notifyListeners();

    try {
      final res = await _quranService.fetchSurahDetail(surahNumber);
      _currentSurah = res['surah'];
      _currentAyatList = res['ayat'];
    } catch (e) {
      _errorMessage = 'Gagal memuat detail Surah: $e';
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  // =========================================================================
  // Murottal Gapless Playlist & Realtime Ayah + Word-by-Word Engine
  // =========================================================================

  /// Plays a surah as a gapless ConcatenatingAudioSource playlist of all its verses.
  /// Each verse's audio is retrieved for [selectedQari], enabling 100% exact real-time sync.
  Future<void> playSurahAyatPlaylist(
    int surahNumber, {
    int startAyatIndex = 0,
  }) async {
    _isAudioLoading = true;
    _loadingSurahNumber = surahNumber;
    _isPlayingFullSurah = true;
    _activeWordIndex = 1;
    notifyListeners();

    try {
      // 1. Fetch Ayats if needed
      SurahModel? targetSurah;
      List<AyatModel> targetAyats = [];

      if (_currentSurah?.nomor == surahNumber && _currentAyatList.isNotEmpty) {
        targetSurah = _currentSurah;
        targetAyats = _currentAyatList;
      } else {
        final res = await _quranService.fetchSurahDetail(surahNumber);
        targetSurah = res['surah'];
        targetAyats = res['ayat'];
        _currentSurah = targetSurah;
        _currentAyatList = targetAyats;
      }

      if (targetSurah == null || targetAyats.isEmpty) {
        throw Exception('Data ayat surah tidak ditemukan.');
      }

      _playingSurah = targetSurah;
      _playingAyatList = targetAyats;
      _currentAyatIndex = startAyatIndex.clamp(0, targetAyats.length - 1);
      _playingAyatNumber = targetAyats[_currentAyatIndex].nomorAyat;

      // 2. Fetch Word-by-Word Timings & Total Surah Duration in parallel
      QuranTimingService()
          .fetchSurahTiming(surahNumber, qariKey: _selectedQari)
          .then((timing) {
        _currentSurahTiming = timing;
        if (timing != null && timing.totalDuration.inMilliseconds > 0) {
          _surahTotalDuration = timing.totalDuration;
        }
        notifyListeners();
      });

      // 3. Build Gapless Concatenating Audio Source
      final audioSources = <AudioSource>[];
      for (final ayat in targetAyats) {
        final url = ayat.audio[_selectedQari] ??
            ayat.audio['05'] ??
            ayat.audio.values.firstOrNull ??
            '';
        if (url.isNotEmpty) {
          audioSources.add(
            AudioSource.uri(
              Uri.parse(url),
              tag: ayat.nomorAyat,
            ),
          );
        }
      }

      if (audioSources.isEmpty) {
        throw Exception('Audio untuk qari ini tidak tersedia.');
      }

      final playlist = ConcatenatingAudioSource(
        useLazyPreparation: true,
        children: audioSources,
      );

      await _audioPlayer.stop();

      // Configure loop mode
      await _applyLoopMode();

      await _audioPlayer.setAudioSource(
        playlist,
        initialIndex: _currentAyatIndex,
        initialPosition: Duration.zero,
      );

      await _audioPlayer.play();
      _isPlayingAudio = true;
    } catch (e) {
      debugPrint('[QuranProvider] playSurahAyatPlaylist error: $e');
      _isPlayingAudio = false;
      _isAudioLoading = false;
    } finally {
      _isAudioLoading = false;
      _loadingSurahNumber = null;
      notifyListeners();
    }
  }

  /// Toggle play / pause
  Future<void> togglePlayPause() async {
    try {
      if (_isPlayingAudio) {
        await _audioPlayer.pause();
        _isPlayingAudio = false;
      } else {
        await _audioPlayer.play();
        _isPlayingAudio = true;
      }
    } catch (e) {
      debugPrint('[QuranProvider] togglePlayPause error: $e');
    } finally {
      notifyListeners();
    }
  }

  /// Skip to Next Surah
  Future<void> nextSurah() async {
    final currentNum = _playingSurah?.nomor ?? _currentSurah?.nomor ?? 1;
    final nextNum = currentNum < 114 ? currentNum + 1 : 1;
    await playSurahAyatPlaylist(nextNum, startAyatIndex: 0);
  }

  /// Skip to Previous Surah
  Future<void> previousSurah() async {
    final currentNum = _playingSurah?.nomor ?? _currentSurah?.nomor ?? 1;
    final prevNum = currentNum > 1 ? currentNum - 1 : 114;
    await playSurahAyatPlaylist(prevNum, startAyatIndex: 0);
  }

  /// Skip to Next Ayat
  Future<void> nextAyat() async {
    if (_audioPlayer.hasNext) {
      await _audioPlayer.seekToNext();
    } else if (_autoNextSurah && _playingSurah != null) {
      final nextSurahNum = _playingSurah!.nomor + 1;
      if (nextSurahNum <= 114) {
        await playSurahAyatPlaylist(nextSurahNum, startAyatIndex: 0);
      }
    }
  }

  /// Skip to Previous Ayat or restart current ayat if played > 3 seconds
  Future<void> previousAyat() async {
    if (_audioPlayer.position > const Duration(seconds: 3) ||
        !_audioPlayer.hasPrevious) {
      await _audioPlayer.seek(Duration.zero);
    } else {
      await _audioPlayer.seekToPrevious();
    }
  }

  /// Seek to specific ayat by index
  Future<void> seekToAyat(int index) async {
    if (index >= 0 && index < _playingAyatList.length) {
      _currentAyatIndex = index;
      _playingAyatNumber = _playingAyatList[index].nomorAyat;
      _activeWordIndex = 1;
      notifyListeners();
      await _audioPlayer.seek(Duration.zero, index: index);
      if (!_isPlayingAudio) {
        await _audioPlayer.play();
        _isPlayingAudio = true;
      }
    }
  }

  /// Seek audio position anywhere across the entire Surah duration
  Future<void> seekSurah(Duration targetSurahPosition) async {
    if (_playingAyatList.isEmpty) return;

    var accumulated = Duration.zero;
    int targetIndex = 0;
    Duration targetOffsetInAyat = Duration.zero;

    for (int i = 0; i < _playingAyatList.length; i++) {
      final ayatDur = getAyatDuration(i);
      if (accumulated + ayatDur >= targetSurahPosition ||
          i == _playingAyatList.length - 1) {
        targetIndex = i;
        targetOffsetInAyat = targetSurahPosition - accumulated;
        if (targetOffsetInAyat < Duration.zero) {
          targetOffsetInAyat = Duration.zero;
        }
        break;
      }
      accumulated += ayatDur;
    }

    _currentAyatIndex = targetIndex;
    _playingAyatNumber = _playingAyatList[targetIndex].nomorAyat;
    _activeWordIndex = 1;
    notifyListeners();

    await _audioPlayer.seek(targetOffsetInAyat, index: targetIndex);
    if (!_isPlayingAudio) {
      await _audioPlayer.play();
      _isPlayingAudio = true;
    }
  }

  /// Seek audio position within currently playing ayat
  Future<void> seekAudio(Duration position) async {
    await seekSurah(position);
  }

  /// Cycle Repeat Mode: off -> repeatSurah -> repeatAyat -> off
  Future<void> toggleRepeatMode() async {
    switch (_repeatMode) {
      case MurottalRepeatMode.off:
        _repeatMode = MurottalRepeatMode.repeatSurah;
        break;
      case MurottalRepeatMode.repeatSurah:
        _repeatMode = MurottalRepeatMode.repeatAyat;
        break;
      case MurottalRepeatMode.repeatAyat:
        _repeatMode = MurottalRepeatMode.off;
        break;
    }
    await _applyLoopMode();
    notifyListeners();
  }

  Future<void> setRepeatMode(MurottalRepeatMode mode) async {
    _repeatMode = mode;
    await _applyLoopMode();
    notifyListeners();
  }

  Future<void> _applyLoopMode() async {
    try {
      if (_repeatMode == MurottalRepeatMode.repeatAyat) {
        await _audioPlayer.setLoopMode(LoopMode.one);
      } else if (_repeatMode == MurottalRepeatMode.repeatSurah) {
        await _audioPlayer.setLoopMode(LoopMode.all);
      } else {
        await _audioPlayer.setLoopMode(LoopMode.off);
      }
    } catch (_) {}
  }

  void toggleAutoNextSurah() {
    _autoNextSurah = !_autoNextSurah;
    notifyListeners();
  }

  // Backwards compatibility methods
  Future<void> playFullSurahAudio(String audioUrl, {int? surahNumber}) async {
    final sNum = surahNumber ?? _currentSurah?.nomor;
    if (sNum != null) {
      await playSurahAyatPlaylist(sNum, startAyatIndex: 0);
    }
  }

  Future<void> playAyatAudio(int ayatNumber, String audioUrl) async {
    final sNum = _currentSurah?.nomor;
    if (sNum != null && _currentAyatList.isNotEmpty) {
      final index =
          _currentAyatList.indexWhere((a) => a.nomorAyat == ayatNumber);
      if (index >= 0) {
        await playSurahAyatPlaylist(sNum, startAyatIndex: index);
      }
    }
  }

  // Stop audio playback completely
  Future<void> stopAudio() async {
    try {
      await _audioPlayer.stop();
    } catch (_) {}
    _playingAyatNumber = null;
    _isPlayingFullSurah = false;
    _isPlayingAudio = false;
    _isAudioLoading = false;
    _loadingSurahNumber = null;
    _activeWordIndex = 1;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
