class UserProfile {
  final int? id;
  final String name;
  final String surname;
  final String email;
  final String sex; // 'M' or 'F'
  final DateTime dateOfBirth;
  final double height; // in cm

  UserProfile({
    this.id,
    required this.name,
    required this.surname,
    required this.email,
    required this.sex,
    required this.dateOfBirth,
    required this.height,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'surname': surname,
      'email': email,
      'sex': sex,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'height': height,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as int?,
      name: map['name'] as String,
      surname: map['surname'] as String,
      email: map['email'] as String,
      sex: map['sex'] as String,
      dateOfBirth: DateTime.parse(map['dateOfBirth'] as String),
      height: map['height'] as double,
    );
  }

  UserProfile copyWith({
    int? id,
    String? name,
    String? surname,
    String? email,
    String? sex,
    DateTime? dateOfBirth,
    double? height,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      email: email ?? this.email,
      sex: sex ?? this.sex,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      height: height ?? this.height,
    );
  }
}
