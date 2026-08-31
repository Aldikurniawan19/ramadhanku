import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/doa_model.dart';

class DoaService {
  final http.Client client;
  DoaService({http.Client? client}) : client = client ?? http.Client();

  final List<DoaModel> fallbackDoaList = [
    DoaModel(
      id: 1,
      judul: "Doa Niat Puasa Ramadhan",
      arab: "نَوَيْتُ صَوْمَ غَدٍ عَنْ أَدَاءِ فَرْضِ شَهْرِ رَمَضَانَ هَذِهِ السَّنَةِ لِلَّهِ تَعَالَى",
      latin: "Nawaitu shauma ghadin 'an adaa-i fardhi syahri ramadhaana hadhihis sanati lillaahi ta'aalaa.",
      terjemah: "Saya niat berpuasa esok hari untuk menunaikan kewajiban bulan Ramadhan tahun ini karena Allah Ta'ala.",
    ),
    DoaModel(
      id: 2,
      judul: "Doa Buka Puasa",
      arab: "ذَهَبَ الظَّمَأُ وَابْتَلَّتِ الْعُرُوقُ وَثَبَتَ الأَجْرُ إِنْ شَاءَ اللَّهُ",
      latin: "Dzahabadh-dhama-u wabtallatil-'uruuqu wa thabatal-ajru insyaa-allaah.",
      terjemah: "Telah hilang rasa haus, urat-urat telah basah, dan pahala telah ditetapkan, insya Allah.",
    ),
    DoaModel(
      id: 3,
      judul: "Doa Lailatul Qadr",
      arab: "اَللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّيْ",
      latin: "Allahumma innaka 'afuwwun tuhibbul 'afwa fa'fu 'anni.",
      terjemah: "Ya Allah, sesungguhnya Engkau Maha Pemaaf dan menyukai maaf, maka maafkanlah aku.",
    ),
    DoaModel(
      id: 4,
      judul: "Doa Sebelum Tidur",
      arab: "بِاسْمِكَ اللّهُمَّ أَحْيَا وَأَمُوْتُ",
      latin: "Bismikallohumma ahyaa wa amuutu.",
      terjemah: "Dengan menyebut nama-Mu ya Allah, aku hidup dan aku mati.",
    ),
    DoaModel(
      id: 5,
      judul: "Doa Bangun Tidur",
      arab: "اَلْحَمْدُ لِلَّهِ الَّذِيْ أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُوْرُ",
      latin: "Alhamdu lillahil ladzii ahyaanaa ba'da maa amaatanaa wa ilaihin nusyuur.",
      terjemah: "Segala puji bagi Allah yang telah menghidupkan kami setelah mematikan kami dan hanya kepada-Nya kami dikembalikan.",
    ),
    DoaModel(
      id: 6,
      judul: "Doa Mohon Kebaikan Dunia dan Akhirat (Sapu Jagat)",
      arab: "رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ",
      latin: "Rabbanaa aatinaa fid-dun-yaa hasanatah, wa fil-aakhirati hasanatah, wa qinaa 'adzaaban-naar.",
      terjemah: "Ya Tuhan kami, berilah kami kebaikan di dunia dan kebaikan di akhirat, dan lindungilah kami dari azab neraka.",
    ),
    DoaModel(
      id: 7,
      judul: "Doa Kedua Orang Tua",
      arab: "رَبِّ اغْفِرْ لِيْ وَلِوَالِدَيَّ وَارْحَمْهُمَا كَمَا رَبَّيَانِيْ صَغِيْرًا",
      latin: "Rabbighfir lii wa liwaalidayya warhamhumaa kamaa rabbayaanii shaghiiraa.",
      terjemah: "Ya Tuhanku, ampunilah aku dan kedua orang tuaku, dan kasihilah mereka berdua sebagaimana mereka telah merawatku sewaktu kecil.",
    ),
    DoaModel(
      id: 8,
      judul: "Doa Sebelum Makan",
      arab: "اَللَّهُمَّ بَارِكْ لَنَا فِيْمَا رَزَقْتَنَا وَقِنَا عَذَابَ النَّارِ",
      latin: "Allahumma baarik lanaa fii maa razaqtanaa wa qinaa 'adzaaban-naar.",
      terjemah: "Ya Allah, berkahilah kami pada rezeki yang telah Engkau berikan kepada kami dan lindungilah kami dari siksa neraka.",
    ),
    DoaModel(
      id: 9,
      judul: "Doa Sesudah Makan",
      arab: "اَلْحَمْدُ لِلَّهِ الَّذِيْ أَطْعَمَنَا وَسَقَانَا وَجَعَلَنَا مُسْلِمِيْنَ",
      latin: "Alhamdu lillahilladzii ath'amanaa wa saqaanaa wa ja'alanaa muslimiin.",
      terjemah: "Segala puji bagi Allah yang telah memberi kami makan dan minum serta menjadikan kami orang-orang Muslim.",
    ),
    DoaModel(
      id: 10,
      judul: "Doa Masuk Masjid",
      arab: "اَللَّهُمَّ افْتَحْ لِيْ أَبْوَابَ رَحْمَتِكَ",
      latin: "Allahummaftah lii abwaaba rahmatik.",
      terjemah: "Ya Allah, bukakanlah untukku pintu-pintu rahmat-Mu.",
    ),
    DoaModel(
      id: 11,
      judul: "Doa Keluar Masjid",
      arab: "اَللَّهُمَّ إِنِّيْ أَسْأَلُكَ مِنْ فَضْلِكَ",
      latin: "Allahumma innii as-aluka min fadhlik.",
      terjemah: "Ya Allah, sesungguhnya aku memohon keutamaan dari-Mu.",
    ),
    DoaModel(
      id: 12,
      judul: "Doa Masuk Rumah",
      arab: "بِسْمِ اللهِ وَلَجْنَا، وَبِسْمِ اللهِ خَرَجْنَا، وَعَلَى رَبِّنَا تَوَكَّلْنَا",
      latin: "Bismillaahi walajnaa, wa bismillaahi kharajnaa, wa 'alaa rabbinaa tawakkalnaa.",
      terjemah: "Dengan nama Allah kami masuk, dan dengan nama Allah kami keluar, dan kepada Tuhan kami, kami bertawakal.",
    ),
    DoaModel(
      id: 13,
      judul: "Doa Keluar Rumah",
      arab: "بِسْمِ اللهِ تَوَكَّلْتُ عَلَى اللهِ، لاَ حَوْلَ وَلاَ قُوَّةَ إِلاَّ بِاللهِ",
      latin: "Bismillaahi tawakkaltu 'alallaahi, laa haula wa laa quwwata illaa billaah.",
      terjemah: "Dengan nama Allah, aku bertawakal kepada Allah. Tiada daya dan kekuatan kecuali dengan pertolongan Allah.",
    ),
    DoaModel(
      id: 14,
      judul: "Doa Masuk Kamar Mandi (WC)",
      arab: "اَللَّهُمَّ إِنِّيْ أَعُوْذُ بِكَ مِنَ الْخُبُثِ وَالْخَبَائِثِ",
      latin: "Allahumma innii a'uudzu bika minal khubutsi wal khabaa-its.",
      terjemah: "Ya Allah, sesungguhnya aku berlindung kepada-Mu dari godaan setan laki-laki dan setan perempuan.",
    ),
    DoaModel(
      id: 15,
      judul: "Doa Keluar Kamar Mandi (WC)",
      arab: "غُفْرَانَكَ اَلْحَمْدُ لِلَّهِ الَّذِيْ أَذْهَبَ عَنِّي الأَذَى وَعَافَانِيْ",
      latin: "Ghufraanaka alhamdu lillahilladzii adzhaba 'annil adzaa wa 'aafaanii.",
      terjemah: "Aku memohon ampunan-Mu. Segala puji bagi Allah yang telah menghilangkan penyakit dariku dan menyembuhkanku.",
    ),
    DoaModel(
      id: 16,
      judul: "Doa Setelah Wudhu",
      arab: "أَشْهَدُ أَنْ لاَ إِلَهَ إِلاَّ اللهُ وَحْدَهُ لاَ شَرِيْكَ لَهُ وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُوْلُهُ",
      latin: "Asyhadu allaa ilaaha illallaahu wahdahu laa syariika lahu, wa asyhadu anna Muhammadan 'abduhu wa rasuuluh.",
      terjemah: "Aku bersaksi tiada Tuhan selain Allah Yang Maha Esa tiada sekutu bagi-Nya, dan aku bersaksi bahwa Nabi Muhammad adalah hamba dan utusan-Nya.",
    ),
    DoaModel(
      id: 17,
      judul: "Doa Setelah Adzan",
      arab: "اَللَّهُمَّ رَبَّ هَذِهِ الدَّعْوَةِ التَّامَّةِ وَالصَّلاَةِ الْقَائِمَةِ آتِ مُحَمَّدًا الْوَسِيْلَةَ وَالْفَضِيْلَةَ وَابْعَثْهُ مَقَامًا مَحْمُوْدًا الَّذِيْ وَعَدْتَهُ",
      latin: "Allahumma rabba haadzihid da'watit taammati wash shalaatil qaa-imati aati Muhammadanil wasiilata wal fadhiilata wab'atshu maqaamam mahmuudanil ladzii wa'adtah.",
      terjemah: "Ya Allah, Tuhan pemilik panggilan yang sempurna ini dan sholat yang didirikan, berikanlah kepada Nabi Muhammad kedudukan tempat yang mulia dan utamakanlah beliau, serta bangkitkanlah beliau pada tempat terpuji yang telah Engkau janjikan.",
    ),
    DoaModel(
      id: 18,
      judul: "Doa Naik Kendaraan",
      arab: "سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ وَإِنَّا إِلَى رَبِّنَا لَمُنْقَلِبُونَ",
      latin: "Subhaanalladzii sakhkhara lanaa haadzaa wa maa kunnaa lahu muqriniina wa innaa ilaa rabbinaa lamunqalibuun.",
      terjemah: "Maha Suci Allah yang telah menundukkan semua ini bagi kami padahal kami sebelumnya tidak mampu menguasainya, dan sesungguhnya kami akan kembali kepada Tuhan kami.",
    ),
    DoaModel(
      id: 19,
      judul: "Doa Ketika Hujan Turun",
      arab: "اَللَّهُمَّ صَيِّبًا نَافِعًا",
      latin: "Allahumma shayyiban naafi'aa.",
      terjemah: "Ya Allah, turunkanlah pada kami hujan yang bermanfaat.",
    ),
    DoaModel(
      id: 20,
      judul: "Doa Terhindar dari Wabah & Penyakit Berat",
      arab: "اَللَّهُمَّ إِنِّيْ أَعُوْذُ بِكَ مِنَ الْبَرَصِ وَالْجُنُوْنِ وَالْجُذَامِ وَمِنْ سَيِّئِ اْلأَسْقَامِ",
      latin: "Allahumma innii a'uudzu bika minal barashi wal junuuni wal judzaami wa min sayyi-il asqaam.",
      terjemah: "Ya Allah, aku berlindung kepada-Mu dari penyakit belang, gila, kusta, dan dari penyakit-penyakit yang buruk.",
    ),
    DoaModel(
      id: 21,
      judul: "Doa Memohon Ilmu Berfaedah & Rezeki Halal",
      arab: "اَللَّهُمَّ إِنِّيْ أَسْأَلُكَ عِلْمًا نَافِعًا وَرِزْقًا طَيِّبًا وَعَمَلاً مُتَقَبَّلاً",
      latin: "Allahumma innii as-aluka 'ilman naafi'an wa rizqan thayyiban wa 'amalan mutaqabbalaa.",
      terjemah: "Ya Allah, sesungguhnya aku memohon kepada-Mu ilmu yang bermanfaat, rezeki yang baik (halal), dan amalan yang diterima.",
    ),
    DoaModel(
      id: 22,
      judul: "Doa Keteguhan Hati (Istiqomah)",
      arab: "يَا مُقَلِّبَ الْقُلُوْبِ ثَبِّتْ قَلْبِيْ عَلَى دِيْنِكَ",
      latin: "Yaa muqallibal quluubi tsabbit qalbii 'alaa diinik.",
      terjemah: "Wahai Dzat yang membolak-balikkan hati, teguhkanlah hatiku di atas agama-Mu.",
    ),
    DoaModel(
      id: 23,
      judul: "Doa Memohon Ampunan Dosa & Rahmat",
      arab: "رَبَّنَا ظَلَمْنَا أَنْفُسَنَا وَإِنْ لَمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنَ الْخَاسِرِينَ",
      latin: "Rabbanaa zhalamnaa anfusanaa wa il-lam taghfir lanaa wa tarhamnaa lanakuunanna minal khaasiriin.",
      terjemah: "Ya Tuhan kami, kami telah menganiaya diri kami sendiri, dan jika Engkau tidak mengampuni kami dan memberi rahmat kepada kami, niscaya kami termasuk orang-orang yang rugi.",
    ),
    DoaModel(
      id: 24,
      judul: "Doa Bercermin",
      arab: "اَللَّهُمَّ كَمَا حَسَّنْتَ خَلْقِيْ فَحَسِّنْ خُلُقِيْ",
      latin: "Allahumma kamaa hassanta khalqii fahassin khuluqii.",
      terjemah: "Ya Allah, sebagaimana Engkau telah memperbagus rupa kejadianku, maka perbaguslah pula akhlakku.",
    ),
    DoaModel(
      id: 25,
      judul: "Doa Memakai Pakaian",
      arab: "اَلْحَمْدُ لِلَّهِ الَّذِيْ كَسَانِيْ هَذَا وَرَزَقَنِيْهِ مِنْ غَيْرِ حَوْلٍ مِنِّيْ وَلاَ قُوَّةٍ",
      latin: "Alhamdu lillahilladzii kasaanii haadzaa wa razaqaniihi min ghairi haulin minnii wa laa quwwah.",
      terjemah: "Segala puji bagi Allah yang telah mengenakan pakaian ini kepadaku dan mengaruniakannya kepadaku tanpa daya dan kekuatan dariku.",
    ),
    DoaModel(
      id: 26,
      judul: "Doa Menjenguk Orang Sakit",
      arab: "أَسْأَلُ اللهَ الْعَظِيْمَ رَبَّ الْعَرْشِ الْعَظِيْمِ أَنْ يَشْفِيَكَ",
      latin: "As-alullaahal 'azhiima rabbal 'arsyil 'azhiimi an yasyfiyak.",
      terjemah: "Aku memohon kepada Allah Yang Maha Agung, Tuhan pemilik 'Arsy yang agung, agar Dia menyembuhkanmu.",
    ),
    DoaModel(
      id: 27,
      judul: "Doa Saat Tertimpa Musibah",
      arab: "إِنَّا لِلَّهِ وَإِنَّا إِلَيْهِ رَاجِعُونَ، اللَّهُمَّ أْجُرْنِي فِي مُصِيبَتِي وَأَخْلِفْ لِي خَيْرًا مِنْهَا",
      latin: "Innaa lillaahi wa innaa ilaihi raaji'uun. Allahumma'-jurnii fii mushiibatii wa akhlif lii khairan minhaa.",
      terjemah: "Sesungguhnya kami milik Allah dan hanya kepada-Nya kami kembali. Ya Allah, berilah aku pahala dalam musibahku ini dan gantikanlah untukku dengan yang lebih baik daripadanya.",
    ),
    DoaModel(
      id: 28,
      judul: "Doa Terhindar dari Sifat Malas & Penakut",
      arab: "اَللَّهُمَّ إِنِّيْ أَعُوْذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ، وَأَعُوْذُ بِكَ مِنَ الْعَجْزِ وَالْكَسَلِ، وَأَعُوْذُ بِكَ مِنَ الْجُبْنِ وَالْبُخْلِ",
      latin: "Allahumma innii a'uudzu bika minal hammi wal hazan, wa a'uudzu bika minal 'ajzi wal kasal, wa a'uudzu bika minal jubni wal bukhli.",
      terjemah: "Ya Allah, sesungguhnya aku berlindung kepada-Mu dari keluh kesah dan duka cita, dari kelemahan dan kemalasan, serta dari sifat penakut dan kikir.",
    ),
    DoaModel(
      id: 29,
      judul: "Doa Memohon Husnul Khatimah",
      arab: "اَللَّهُمَّ إِذَا حَضَرَتْ وَفَاتِيْ فَاجْعَلْ خَيْرَ أَيَّامِيْ يَوْمَ أَلْقَاكَ فِيهِ",
      latin: "Allahumma idzaa hadharat wafaatii faj'al khaira ayyaamii yauma alqaaka fiih.",
      terjemah: "Ya Allah, apabila telah datang ajalku, jadikanlah sebaik-baik hariku adalah hari di mana aku bertemu dengan-Mu.",
    ),
    DoaModel(
      id: 30,
      judul: "Doa Penutup Majelis (Kaffaratul Majelis)",
      arab: "سُبْحَانَكَ اللَّهُمَّ وَبِحَمْدِكَ، أَشْهَدُ أَنْ لاَ إِلَهَ إِلاَّ أَنْتَ، أَسْتَغْفِرُكَ وَأَتُوْبُ إِلَيْكَ",
      latin: "Subhaanakallahumma wa bihamdika, asyhadu allaa ilaaha illaa anta, astaghfiruka wa atuubu ilaik.",
      terjemah: "Maha Suci Engkau ya Allah dan dengan memuji-Mu, aku bersaksi bahwa tidak ada Tuhan selain Engkau, aku memohon ampunan-Mu dan bertobat kepada-Mu.",
    ),
  ];

  Future<List<DoaModel>> fetchAllDoa() async {
    final List<String> endpoints = [
      ApiConstants.equranDoaUrl,
      'https://open-api.myquran.com/v2/doa/semua',
      'https://api.myquran.com/v2/doa/semua',
      'https://islamic-api-zhirrr.vercel.app/api/doa',
    ];

    for (final url in endpoints) {
      try {
        final res = await client
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 8));

        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          List? listData;

          if (body is Map && body['data'] is List) {
            listData = body['data'];
          } else if (body is List) {
            listData = body;
          }

          if (listData != null && listData.isNotEmpty) {
            return listData.map((json) => DoaModel.fromJson(json)).toList();
          }
        }
      } catch (_) {}
    }

    // Return extended curated fallback dataset (30 Doa)
    return fallbackDoaList;
  }
}
