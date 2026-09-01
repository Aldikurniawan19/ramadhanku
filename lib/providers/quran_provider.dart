import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/surah_model.dart';
import '../data/models/ayat_model.dart';
import '../data/services/quran_service.dart';
import '../data/services/firebase_service.dart';

class QuranProvider extends ChangeNotifier {
  final QuranService _quranService = QuranService();
  final AudioPlayer _audioPlayer = AudioPlayer();

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
  int? _playingAyatNumber;
  bool _isPlayingFullSurah = false;
  bool _isPlayingAudio = false;
  bool _isAudioLoading = false;
  int? _loadingSurahNumber;

  // Last Read State (Default Fresh Start for New Account: Al-Fatihah 1:1, Juz 1)
  String _lastReadSurahName = 'Surah Al-Fatihah';
  int _lastReadSurahNumber = 1;
  int _lastReadAyatNumber = 1;
  int _lastReadJuzNumber = 1;

  List<SurahModel> get surahList => _filteredSurahList;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;
  Set<int> get bookmarkedSurahs => _bookmarkedSurahs;

  SurahModel? get currentSurah => _currentSurah;
  List<AyatModel> get currentAyatList => _currentAyatList;
  bool get isLoadingDetail => _isLoadingDetail;
  int? get playingAyatNumber => _playingAyatNumber;
  bool get isPlayingFullSurah => _isPlayingFullSurah;
  bool get isPlayingAudio => _isPlayingAudio;
  bool get isAudioLoading => _isAudioLoading;
  int? get loadingSurahNumber => _loadingSurahNumber;

  String get lastReadSurahName => _lastReadSurahName;
  int get lastReadSurahNumber => _lastReadSurahNumber;
  int get lastReadAyatNumber => _lastReadAyatNumber;
  int get lastReadJuzNumber => _lastReadJuzNumber;

  QuranProvider() {
    loadSurahs();
    reloadUserData();
    _initAudioListeners();
  }

  Future<void> reloadUserData() async {
    final uid = await FirebaseService().getEffectiveUserId();
    final prefs = await SharedPreferences.getInstance();
    _lastReadSurahName = prefs.getString('quran_surah_name_$uid') ?? 'Surah Al-Fatihah';
    _lastReadSurahNumber = prefs.getInt('quran_surah_num_$uid') ?? 1;
    _lastReadAyatNumber = prefs.getInt('quran_ayat_num_$uid') ?? 1;
    _lastReadJuzNumber = prefs.getInt('quran_juz_num_$uid') ?? 1;
    final bookmarksList = prefs.getStringList('quran_bookmarks_$uid') ?? [];
    _bookmarkedSurahs = bookmarksList.map((e) => int.tryParse(e) ?? 0).where((n) => n > 0).toSet();
    notifyListeners();

    // Sync from Firebase Cloud Firestore if available
    try {
      final cloudLastRead = await FirebaseService().getLastReadQuran();
      if (cloudLastRead != null) {
        final sName = cloudLastRead['surahName'] as String? ?? _lastReadSurahName;
        final sNum = cloudLastRead['surahNumber'] as int? ?? _lastReadSurahNumber;
        final aNum = cloudLastRead['ayatNumber'] as int? ?? _lastReadAyatNumber;
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

    // Save to Firebase Cloud Firestore
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
        _playingAyatNumber = null;
        _isPlayingFullSurah = false;
        _isPlayingAudio = false;
        _isAudioLoading = false;
        _loadingSurahNumber = null;
      }
      notifyListeners();
    });
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
      // Search filter
      bool matchesSearch = matchesSurahSearch(s, _searchQuery);

      // Category filter (Semua, Makkiyah, Madaniyah)
      bool matchesCategory = true;
      if (_selectedCategory == 'Makkiyah') {
        final tt = s.tempatTurun.toLowerCase();
        matchesCategory = tt.contains('mekah') || tt.contains('mekan') || tt.contains('makki');
      } else if (_selectedCategory == 'Madaniyah') {
        final tt = s.tempatTurun.toLowerCase();
        matchesCategory = tt.contains('madinah') || tt.contains('madin') || tt.contains('madan');
      }

      return matchesSearch && matchesCategory;
    }).toList();
  }

  /// Logic pencarian fleksibel untuk nama surah Al-Qur'an (misal: "annas" -> "An-Nas")
  bool matchesSurahSearch(SurahModel surah, String rawQuery) {
    final query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) return true;

    // 1. Nomor surah (misal: "1", "114", "36")
    final String surahNumStr = surah.nomor.toString();
    if (surahNumStr == query || surahNumStr.startsWith(query)) {
      return true;
    }

    // Hapus awalan kata "surah", "surat", "qs", "qs." jika ada
    String cleanQueryStr = query
        .replaceAll(RegExp(r"^(surah|surat|qs\.?)\s+"), "")
        .trim();
    if (cleanQueryStr.isEmpty) cleanQueryStr = query;

    if (surahNumStr == cleanQueryStr) return true;

    // 2. Pencocokan arti surah
    final String arti = surah.arti.toLowerCase();
    if (arti.contains(cleanQueryStr) || arti.contains(query)) {
      return true;
    }

    // 3. Pencocokan nama Arab
    if (surah.nama.contains(cleanQueryStr) || surah.nama.contains(query)) {
      return true;
    }

    // 4. Pencocokan nama Latin (Fleksibel tanpa tanda hubung / simbol)
    final String namaLatin = surah.namaLatin.toLowerCase();

    // Direct substring
    if (namaLatin.contains(cleanQueryStr) || namaLatin.contains(query)) {
      return true;
    }

    // Helper 1: Hapus simbol (tanda hubung, petik, spasi, dll)
    String cleanPunctuation(String text) {
      return text.replaceAll(RegExp(r"[^a-z0-9]"), "");
    }

    final cleanName = cleanPunctuation(namaLatin);
    final cleanQ = cleanPunctuation(cleanQueryStr);

    if (cleanQ.isNotEmpty &&
        (cleanName.contains(cleanQ) || cleanQ.contains(cleanName))) {
      return true;
    }

    // Helper 2: Gabungkan huruf ganda berdampingan ('aa' -> 'a', 'ss' -> 's')
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

    // Helper 3: Normalisasi fonetik ejaan Indonesia (misal: ts/th -> t, sy/sh -> s, kh -> h, dz/dh -> z)
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
    _audioPlayer.stop();
    _playingAyatNumber = null;
    _isPlayingFullSurah = false;
    _isPlayingAudio = false;
    _isAudioLoading = false;
    _loadingSurahNumber = null;
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

  // Play full surah audio
  Future<void> playFullSurahAudio(String audioUrl, {int? surahNumber}) async {
    if (audioUrl.isEmpty) return;
    try {
      if (_isPlayingFullSurah && _isPlayingAudio) {
        await _audioPlayer.pause();
        _isPlayingAudio = false;
        _isAudioLoading = false;
        _loadingSurahNumber = null;
      } else if (_isPlayingFullSurah && !_isPlayingAudio) {
        _isAudioLoading = true;
        if (surahNumber != null) _loadingSurahNumber = surahNumber;
        notifyListeners();
        await _audioPlayer.play();
        _isPlayingAudio = true;
      } else {
        _playingAyatNumber = null;
        _isPlayingFullSurah = true;
        _isAudioLoading = true;
        if (surahNumber != null) _loadingSurahNumber = surahNumber;
        notifyListeners();
        await _audioPlayer.setUrl(audioUrl);
        await _audioPlayer.play();
        _isPlayingAudio = true;
      }
    } catch (e) {
      _isPlayingFullSurah = false;
      _isPlayingAudio = false;
      _isAudioLoading = false;
      _loadingSurahNumber = null;
    } finally {
      notifyListeners();
    }
  }

  // Play single ayat audio
  Future<void> playAyatAudio(int ayatNumber, String audioUrl) async {
    if (audioUrl.isEmpty) return;
    try {
      _isPlayingFullSurah = false;
      if (_playingAyatNumber == ayatNumber && _isPlayingAudio) {
        await _audioPlayer.pause();
        _isPlayingAudio = false;
        _isAudioLoading = false;
      } else {
        _playingAyatNumber = ayatNumber;
        _isAudioLoading = true;
        notifyListeners();
        await _audioPlayer.setUrl(audioUrl);
        await _audioPlayer.play();
        _isPlayingAudio = true;
      }
    } catch (e) {
      _playingAyatNumber = null;
      _isPlayingAudio = false;
      _isAudioLoading = false;
    } finally {
      notifyListeners();
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
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
