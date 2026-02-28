import 'dart:convert';

class UserProfile {
  final String sex;
  final int age;
  final double heightCm;
  final double weightKg;
  final double dailyScreenTimeHours;

  const UserProfile({
    required this.sex,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.dailyScreenTimeHours,
  });

  Map<String, dynamic> toMap() => {
        'sex': sex,
        'age': age,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'dailyScreenTimeHours': dailyScreenTimeHours,
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        sex: map['sex'] as String,
        age: map['age'] as int,
        heightCm: (map['heightCm'] as num).toDouble(),
        weightKg: (map['weightKg'] as num).toDouble(),
        dailyScreenTimeHours: (map['dailyScreenTimeHours'] as num).toDouble(),
      );

  String toJson() => jsonEncode(toMap());
  factory UserProfile.fromJson(String json) =>
      UserProfile.fromMap(jsonDecode(json) as Map<String, dynamic>);
}
