class DoaModel {
  final dynamic id;
  final String judul;
  final String arab;
  final String latin;
  final String terjemah;
  final bool isBookmarked;

  DoaModel({
    required this.id,
    required this.judul,
    required this.arab,
    required this.latin,
    required this.terjemah,
    this.isBookmarked = false,
  });

  factory DoaModel.fromJson(Map<String, dynamic> json) {
    return DoaModel(
      id: json['id'] ?? json['nomor'] ?? '',
      judul: json['judul'] ?? json['nama'] ?? 'Doa',
      arab: json['arab'] ?? json['ar'] ?? json['doa'] ?? '',
      latin: json['latin'] ?? json['tr'] ?? '',
      terjemah: json['terjemah'] ?? json['idn'] ?? json['artinya'] ?? '',
    );
  }

  DoaModel copyWith({bool? isBookmarked}) {
    return DoaModel(
      id: id,
      judul: judul,
      arab: arab,
      latin: latin,
      terjemah: terjemah,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }
}
