class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String city;
  final int totalFastingDays;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.city = 'Jakarta, Indonesia',
    this.totalFastingDays = 0,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? 'Hamba Allah',
      city: map['city'] ?? 'Jakarta, Indonesia',
      totalFastingDays: map['totalFastingDays'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'city': city,
      'totalFastingDays': totalFastingDays,
    };
  }
}
