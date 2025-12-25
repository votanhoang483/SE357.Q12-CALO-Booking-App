class UserModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String email;

  UserModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.email,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      id: data['id'] as String,
      name: data['name'] as String,
      phoneNumber: data['phoneNumber'] as String,
      email: data['email'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'phoneNumber': phoneNumber, 'email': email};
  }
}
