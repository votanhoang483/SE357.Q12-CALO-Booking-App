// Create a CourtModel for Firestore data.
// Fields:
// - id (documentId)
// - name (String)
// - location (String)
// - pricePerHour (int)
// - isActive (bool)
//
// Requirements:
// - fromFirestore factory constructor
// - toMap method

class CourtModel {
  final String id;
  final String name;
  final String location;
  final int pricePerHour;
  final bool isActive;

  CourtModel({
    required this.id,
    required this.name,
    required this.location,
    required this.pricePerHour,
    required this.isActive,
  });

  factory CourtModel.fromFirestore(
  Map<String, dynamic> data,
  String id,
) {
  return CourtModel(
    id: id,
    name: data['name'] ?? '',
    location: data['location'] ?? '',
    pricePerHour: data['pricePerHour'] is int
        ? data['pricePerHour']
        : int.tryParse(data['pricePerHour'].toString()) ?? 0,
    isActive: data['isActive'] ?? false,
  );
}


  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
      'pricePerHour': pricePerHour,
      'isActive': isActive,
    };
  }
}
