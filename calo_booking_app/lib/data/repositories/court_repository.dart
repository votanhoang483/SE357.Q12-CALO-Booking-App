// Create CourtRepository to fetch courts from Cloud Firestore.
// Collection name: 'courts'
//
// Functions:
// - getAllActiveCourts()
//   - return List<CourtModel>
//   - only where isActive == true

import 'package:calo_booking_app/data/models/court_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CourtRepository {
  final FirebaseFirestore _firestore;

  CourtRepository(this._firestore);

  Future<List<CourtModel>> getAllActiveCourts() async {
    final querySnapshot = await _firestore
        .collection('courts')
        .where('isActive', isEqualTo: true)
        .get();


    return querySnapshot.docs.map((doc) {
      return CourtModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }
}