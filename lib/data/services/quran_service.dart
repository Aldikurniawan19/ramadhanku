import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/surah_model.dart';
import '../models/ayat_model.dart';

class QuranService {
  final http.Client client;
  QuranService({http.Client? client}) : client = client ?? http.Client();

  final Map<int, Map<String, dynamic>> _detailCache = {};
  List<SurahModel>? _surahsCache;

  // Primary & Secondary Backup Endpoints
  static const List<String> _suratEndpoints = [
    '${ApiConstants.equranBaseUrl}/surat',
    'https://equran.nos.jkt-1.neo.id/api/v2/surat',
  ];

  Future<List<SurahModel>> fetchAllSurahs() async {
    if (_surahsCache != null && _surahsCache!.isNotEmpty) {
      return _surahsCache!;
    }

    Object? lastError;
    for (final url in _suratEndpoints) {
      try {
        final response = await client
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 20));

        if (response.statusCode == 200) {
          final Map<String, dynamic> body = jsonDecode(response.body);
          final List<dynamic> data = body['data'] ?? [];
          if (data.isNotEmpty) {
            _surahsCache = data.map((json) => SurahModel.fromJson(json)).toList();
            return _surahsCache!;
          }
        }
      } catch (e) {
        lastError = e;
      }
    }

    if (_surahsCache != null && _surahsCache!.isNotEmpty) return _surahsCache!;
    throw Exception('Gagal terhubung ke API Quran. Pastikan koneksi internet Anda aktif. (${lastError ?? "Timeout"})');
  }

  Future<Map<String, dynamic>> fetchSurahDetail(int surahNumber) async {
    if (_detailCache.containsKey(surahNumber)) {
      return _detailCache[surahNumber]!;
    }

    final detailEndpoints = [
      '${ApiConstants.equranBaseUrl}/surat/$surahNumber',
      'https://equran.nos.jkt-1.neo.id/api/v2/surat/$surahNumber',
    ];

    Object? lastError;
    for (final url in detailEndpoints) {
      try {
        final response = await client
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 20));

        if (response.statusCode == 200) {
          final Map<String, dynamic> body = jsonDecode(response.body);
          final Map<String, dynamic> data = body['data'] ?? {};
          
          final surahInfo = SurahModel.fromJson(data);
          final List<dynamic> ayatListRaw = data['ayat'] ?? [];
          final List<AyatModel> ayatList = ayatListRaw
              .map((json) => AyatModel.fromJson(json))
              .toList();

          final result = {
            'surah': surahInfo,
            'ayat': ayatList,
          };
          _detailCache[surahNumber] = result;
          return result;
        }
      } catch (e) {
        lastError = e;
      }
    }

    if (_detailCache.containsKey(surahNumber)) {
      return _detailCache[surahNumber]!;
    }
    throw Exception('Gagal memuat detail Surah $surahNumber (${lastError ?? "Timeout"})');
  }
}
