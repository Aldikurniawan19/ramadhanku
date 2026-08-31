import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/hadits_model.dart';

class HaditsService {
  static const String _cdnUrl = 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions';
  static const String _myQuranUrl = 'https://api.myquran.com/v2/hadits';

  Future<List<HaditsModel>> fetchHadits({String book = 'bukhari', int limit = 100}) async {
    final editionBook = _mapBookSlug(book);
    final bookDisplayName = _mapBookDisplayName(book);

    // 1. Try High-Performance CDN Hadits API (Arabic + Indonesian paired)
    try {
      final araFuture = http
          .get(Uri.parse('$_cdnUrl/ara-$editionBook.min.json'))
          .timeout(const Duration(seconds: 10));
      final indFuture = http
          .get(Uri.parse('$_cdnUrl/ind-$editionBook.min.json'))
          .timeout(const Duration(seconds: 10));

      final responses = await Future.wait([araFuture, indFuture]);
      final araRes = responses[0];
      final indRes = responses[1];

      if (indRes.statusCode == 200) {
        final indData = json.decode(indRes.body);
        final List indItems = indData['hadiths'] ?? [];

        List araItems = [];
        if (araRes.statusCode == 200) {
          final araData = json.decode(araRes.body);
          araItems = araData['hadiths'] ?? [];
        }

        if (indItems.isNotEmpty) {
          final List<HaditsModel> result = [];
          final count = indItems.length < limit ? indItems.length : limit;

          for (int i = 0; i < count; i++) {
            final Map<String, dynamic> item = Map<String, dynamic>.from(indItems[i]);
            if (i < araItems.length && araItems[i]['text'] != null) {
              item['arab'] = araItems[i]['text'];
            }
            result.add(HaditsModel.fromJson(item, defaultBook: bookDisplayName));
          }
          return result;
        }
      }
    } catch (_) {}

    // 2. Try Secondary MyQuran API
    try {
      final response = await http
          .get(Uri.parse('$_myQuranUrl/$book/1'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true && data['data'] != null) {
          final item = Map<String, dynamic>.from(data['data']);
          item['book'] = bookDisplayName;
          return [HaditsModel.fromJson(item, defaultBook: bookDisplayName)];
        }
      }
    } catch (_) {}

    // 3. Offline / Fallback Curated Authentic Hadiths Dataset (25 Hadiths)
    return _getFallbackHadits();
  }

  String _mapBookSlug(String book) {
    switch (book.toLowerCase()) {
      case 'muslim':
        return 'muslim';
      case 'tirmidzi':
      case 'tirmidhi':
        return 'tirmidhi';
      case 'abudawud':
      case 'abu-daud':
        return 'abudawud';
      case 'nasai':
        return 'nasai';
      case 'ibnmajah':
      case 'ibnu-majah':
        return 'ibnmajah';
      case 'bukhari':
      default:
        return 'bukhari';
    }
  }

  String _mapBookDisplayName(String book) {
    switch (book.toLowerCase()) {
      case 'muslim':
        return 'HR. Muslim';
      case 'tirmidzi':
      case 'tirmidhi':
        return 'HR. Tirmidzi';
      case 'abudawud':
      case 'abu-daud':
        return 'HR. Abu Daud';
      case 'nasai':
        return 'HR. Nasai';
      case 'ibnmajah':
      case 'ibnu-majah':
        return 'HR. Ibnu Majah';
      case 'bukhari':
      default:
        return 'HR. Bukhari';
    }
  }

  List<HaditsModel> _getFallbackHadits() {
    return [
      HaditsModel(
        id: '1',
        book: 'HR. Bukhari',
        number: 1901,
        title: 'Keutamaan Puasa Ramadhan',
        category: 'Puasa',
        arab: 'مَنْ صَامَ رَمَضَانَ إِيمَانًا وَاحْتِسَابًا غُفِرَ لَهُ مَا تَقَدَّمَ مِنْ ذَنْبِهِ',
        idTranslation:
            'Barangsiapa berpuasa Ramadhan karena iman dan mengharapkan pahala dari Allah, niscaya diampuni dosa-dosanya yang telah lalu.',
      ),
      HaditsModel(
        id: '2',
        book: 'HR. Muslim',
        number: 1151,
        title: 'Keutamaan Bersegera Buka Puasa',
        category: 'Puasa',
        arab: 'لاَ يَزَالُ النَّاسُ بِخَيْرٍ مَا عَجَّلُوا الْفِطْرَ',
        idTranslation:
            'Manusia akan senantiasa berada dalam kebaikan selama mereka menyegerakan berbuka puasa.',
      ),
      HaditsModel(
        id: '3',
        book: 'HR. Bukhari',
        number: 1923,
        title: 'Keberkahan Makan Sahur',
        category: 'Sahur',
        arab: 'تَسَحَّرُوا فَإِنَّ فِي السَّحُورِ بَرَكَةً',
        idTranslation:
            'Makan sahurlah kalian, karena sesungguhnya pada makan sahur itu terdapat keberkahan.',
      ),
      HaditsModel(
        id: '4',
        book: 'HR. Bukhari',
        number: 2014,
        title: 'Mencari Lailatul Qadar',
        category: 'Ramadhan',
        arab: 'تَحَرَّوْا لَيْلَةَ الْقَدْرِ فِي الْوِتْرِ مِنَ الْعَشْرِ الأَوَاخِرِ مِنْ رَمَضَانَ',
        idTranslation:
            'Carilah Lailatul Qadar pada malam-malam ganjil di sepuluh malam terakhir bulan Ramadhan.',
      ),
      HaditsModel(
        id: '5',
        book: 'HR. Muslim',
        number: 2699,
        title: 'Menuntut Ilmu Agama',
        category: 'Ilmu',
        arab: 'مَنْ سَلَكَ طَرِيقًا يَلْتَمِسُ فِيهِ عِلْمًا سَهَّلَ اللَّهُ لَهُ بِهِ طَرِيقًا إِلَى الْجَنَّةِ',
        idTranslation:
            'Barangsiapa menempuh suatu jalan untuk menuntut ilmu, maka Allah akan memudahkan baginya jalan menuju surga.',
      ),
      HaditsModel(
        id: '6',
        book: 'HR. Bukhari',
        number: 13,
        title: 'Mencintai Sesama Muslim',
        category: 'Akhlak',
        arab: 'لاَ يُؤْمِنُ أَحَدُكُمْ حَتَّى يُحِبَّ لأَخِيهِ مَا يُحِبُّ لِنَفْسِهِ',
        idTranslation:
            'Tidak sempurna iman salah seorang di antara kalian sampai ia mencintai untuk saudaranya apa yang ia cintai untuk dirinya sendiri.',
      ),
      HaditsModel(
        id: '7',
        book: 'HR. Tirmidzi',
        number: 1987,
        title: 'Senyum Adalah Sedekah',
        category: 'Akhlak',
        arab: 'تَبَسُّمُكَ فِي وَجْهِ أَخِيكَ لَكَ صَدَقَةٌ',
        idTranslation:
            'Senyummu di hadapan saudaramu adalah (bernilai) sedekah bagimu.',
      ),
      HaditsModel(
        id: '8',
        book: 'HR. Muslim',
        number: 2564,
        title: 'Sedekah Tidak Mengurangi Harta',
        category: 'Sedekah',
        arab: 'مَا نَقَصَتْ صَدَقَةٌ مِنْ مَالٍ',
        idTranslation:
            'Sedekah itu tidak akan mengurangi harta sedikitpun.',
      ),
      HaditsModel(
        id: '9',
        book: 'HR. Bukhari',
        number: 1,
        title: 'Niat dalam Setiap Amalan',
        category: 'Niat',
        arab: 'إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى',
        idTranslation:
            'Sesungguhnya setiap amalan tergantung pada niatnya, dan sesungguhnya setiap orang hanya akan mendapatkan apa yang ia niatkan.',
      ),
      HaditsModel(
        id: '10',
        book: 'HR. Muslim',
        number: 223,
        title: 'Kebersihan Sebagian dari Iman',
        category: 'Akhlak',
        arab: 'الطَّهُورُ شَطْرُ الإِيمَانِ',
        idTranslation:
            'Bersuci (kebersihan) itu adalah separuh dari keimanan.',
      ),
      HaditsModel(
        id: '11',
        book: 'HR. Tirmidzi',
        number: 2910,
        title: 'Pahala Membaca Al-Qur\'an',
        category: 'Al-Qur\'an',
        arab: 'مَنْ قَرَأَ حَرْفًا مِنْ كِتَابِ اللَّهِ فَلَهُ بِهِ حَسَنَةٌ وَالْحَسَنَةُ بِعَشْرِ أَمْثَالِهَا',
        idTranslation:
            'Barangsiapa membaca satu huruf dari Kitabullah (Al-Qur\'an), maka baginya satu kebaikan, dan satu kebaikan dilipatgandakan menjadi sepuluh kali lipat.',
      ),
      HaditsModel(
        id: '12',
        book: 'HR. Bukhari',
        number: 5027,
        title: 'Sebaik-baik Manusia Belajar Al-Qur\'an',
        category: 'Al-Qur\'an',
        arab: 'خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ',
        idTranslation:
            'Sebaik-baik kalian adalah orang yang mempelajari Al-Qur\'an dan mengajarkannya.',
      ),
      HaditsModel(
        id: '13',
        book: 'HR. Bukhari',
        number: 527,
        title: 'Sholat Pada Waktunya',
        category: 'Sholat',
        arab: 'الصَّلاَةُ عَلَى وَقْتِهَا',
        idTranslation:
            'Amalan yang paling dicintai Allah adalah sholat pada waktunya.',
      ),
      HaditsModel(
        id: '14',
        book: 'HR. Bukhari',
        number: 6474,
        title: 'Menjaga Lisan dan Kehormatan',
        category: 'Akhlak',
        arab: 'مَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَالْيَوْمِ الآخِرِ فَلْيَقُلْ خَيْرًا أَوْ لِيَصْمُتْ',
        idTranslation:
            'Barangsiapa yang beriman kepada Allah dan hari akhir, hendaklah ia berkata yang baik atau diam.',
      ),
      HaditsModel(
        id: '15',
        book: 'HR. Muslim',
        number: 2691,
        title: 'Keutamaan Berdzikir',
        category: 'Dzikir',
        arab: 'مَثَلُ الَّذِي يَذْكُرُ رَبَّهُ وَالَّذِي لاَ يَذْكُرُ رَبَّهُ مَثَلُ الْحَيِّ وَالْمَيِّتِ',
        idTranslation:
            'Perumpamaan orang yang berdzikir mengingat Rabbnya dan orang yang tidak berdzikir adalah seperti orang yang hidup dan orang yang mati.',
      ),
      HaditsModel(
        id: '16',
        book: 'HR. Bukhari',
        number: 5971,
        title: 'Berbakti Kepada Orang Tua',
        category: 'Akhlak',
        arab: 'رِضَا الرَّبِّ فِي رِضَا الْوَالِدَيْنِ وَسَخَطُ الرَّبِّ فِي سَخَطِ الْوَالِدَيْنِ',
        idTranslation:
            'Ridha Allah tergantung pada ridha kedua orang tua, dan murka Allah tergantung pada murka kedua orang tua.',
      ),
      HaditsModel(
        id: '17',
        book: 'HR. Bukhari',
        number: 5986,
        title: 'Menjaga Tali Silaturahmi',
        category: 'Akhlak',
        arab: 'مَنْ أَحَبَّ أَنْ يُبْسَطَ لَهُ فِي رِزْقِهِ وَيُنْسَأَ لَهُ فِي أَثَرِهِ فَلْيَصِلْ رَحِمَهُ',
        idTranslation:
            'Barangsiapa yang ingin dilapangkan rezekinya dan dipanjangkan umurnya, hendaklah ia menyambung tali silaturahmi.',
      ),
      HaditsModel(
        id: '18',
        book: 'HR. Muslim',
        number: 49,
        title: 'Mencegah Kemungkaran',
        category: 'Akhlak',
        arab: 'مَنْ رَأَى مِنْكُمْ مُنْكَرًا فَلْيُغَيِّرْهُ بِيَدِهِ فَإِنْ لَمْ يَسْتَطِعْ فَبِلِسَانِهِ',
        idTranslation:
            'Barangsiapa di antara kalian melihat kemungkaran, hendaklah ia merubahnya dengan tangannya, jika tidak mampu maka dengan lisannya.',
      ),
      HaditsModel(
        id: '19',
        book: 'HR. Muslim',
        number: 384,
        title: 'Keutamaan Menjawab Adzan',
        category: 'Sholat',
        arab: 'إِذَا سَمِعْتُمُ الْمُؤَذِّنَ فَقُولُوا مِثْلَ مَا يَقُولُ ثُمَّ صَلُّوا عَلَىَّ',
        idTranslation:
            'Jika kalian mendengar muadzin mengumandangkan adzan, ucapkanlah seperti apa yang diucapkannya, kemudian bersholawatlah kepadaku.',
      ),
      HaditsModel(
        id: '20',
        book: 'HR. Bukhari',
        number: 6066,
        title: 'Menghindari Prasangka Buruk',
        category: 'Akhlak',
        arab: 'إِيَّاكُمْ وَالظَّنَّ فَإِنَّ الظَّنَّ أَكْذَبُ الْحَدِيثِ',
        idTranslation:
            'Jauhilah oleh kalian prasangka buruk, karena prasangka buruk itu adalah sekeruh-keruh ucapan.',
      ),
      HaditsModel(
        id: '21',
        book: 'HR. Tirmidzi',
        number: 3598,
        title: 'Doa Orang Berpuasa Mustajab',
        category: 'Puasa',
        arab: 'ثَلاَثَةٌ لاَ تُرَدُّ دَعْوَتُهُمُ الصَّائِمُ حَتَّى يُفْطِرَ وَالإِمَامُ الْعَادِلُ وَدَعْوَةُ الْمَظْلُومِ',
        idTranslation:
            'Ada tiga orang yang doanya tidak akan ditolak: orang yang berpuasa hingga ia berbuka, pemimpin yang adil, dan doa orang yang terzalimi.',
      ),
      HaditsModel(
        id: '22',
        book: 'HR. Muslim',
        number: 2702,
        title: 'Anjuran Istighfar dan Taubat',
        category: 'Dzikir',
        arab: 'إِنِّي لأَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ فِي الْيَوْمِ مَأَةَ مَرَّةٍ',
        idTranslation:
            'Sesungguhnya aku beristighfar memohon ampunan kepada Allah dan bertobat kepada-Nya dalam sehari sebanyak 100 kali.',
      ),
      HaditsModel(
        id: '23',
        book: 'HR. Tirmidzi',
        number: 2004,
        title: 'Kemuliaan Akhlak yang Baik',
        category: 'Akhlak',
        arab: 'أَكْمَلُ الْمُؤْمِنِينَ إِيمَانًا أَحْسَنُهُمْ خُلُقًا',
        idTranslation:
            'Orang mukmin yang paling sempurna imannya adalah yang paling baik akhlaknya.',
      ),
      HaditsModel(
        id: '24',
        book: 'HR. Bukhari',
        number: 6014,
        title: 'Menjaga Hubungan Baik dengan Tetangga',
        category: 'Akhlak',
        arab: 'مَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَالْيَوْمِ الآخِرِ فَلْيُكْرِمْ جَارَهُ',
        idTranslation:
            'Barangsiapa yang beriman kepada Allah dan hari akhir, hendaklah ia memuliakan tetangganya.',
      ),
      HaditsModel(
        id: '25',
        book: 'HR. Tirmidzi',
        number: 1924,
        title: 'Kasih Sayang Terhadap Makhluk',
        category: 'Akhlak',
        arab: 'ارْحَمُوا مَنْ فِي الأَرْضِ يَرْحَمْكُمْ مَنْ فِي السَّمَاءِ',
        idTranslation:
            'Sayangilah yang ada di bumi, niscaya yang ada di langit akan menyayangimu.',
      ),
    ];
  }
}
