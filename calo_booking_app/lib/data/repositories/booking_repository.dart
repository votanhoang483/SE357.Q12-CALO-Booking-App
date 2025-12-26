import 'package:cloud_firestore/cloud_firestore.dart';

class BookingRepository {
  final FirebaseFirestore _firestore;

  BookingRepository(this._firestore);

  // Create a new booking with detailed slot information
  Future<String> createBookingWithSlots(
    Map<String, dynamic> bookingData,
    List<Map<String, dynamic>> slots,
  ) async {
    try {
      print('💾 Creating booking with ${slots.length} slots');

      final docRef = await _firestore.collection('bookings').add({
        ...bookingData,
        'slots': slots, // Lưu chi tiết từng slot
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Booking created with ID: ${docRef.id}');
      print('📊 Slots saved:');
      for (var slot in slots) {
        print(
          '  - ${slot['court']}: ${slot['startTime']} - ${slot['endTime']}',
        );
      }

      return docRef.id;
    } catch (e) {
      print('❌ Error creating booking with slots: $e');
      rethrow;
    }
  }

  // Create a new booking
  Future<String> createBooking(Map<String, dynamic> bookingData) async {
    try {
      final docRef = await _firestore.collection('bookings').add({
        ...bookingData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      print('Error creating booking: $e');
      rethrow;
    }
  }

  // Get booking by ID
  Future<Map<String, dynamic>?> getBookingById(String bookingId) async {
    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      if (doc.exists) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }
      return null;
    } catch (e) {
      print('Error fetching booking: $e');
      return null;
    }
  }

  // Get all bookings for a user
  Future<List<Map<String, dynamic>>> getUserBookings(String userId) async {
    try {
      print('🔥 Querying bookings for userId: $userId');
      final querySnapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      print('✅ Found ${querySnapshot.docs.length} bookings for $userId');

      return querySnapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    } catch (e) {
      print('❌ Error fetching user bookings: $e');
      return [];
    }
  }

  // Get all bookings
  Future<List<Map<String, dynamic>>> getAllBookings() async {
    try {
      final querySnapshot = await _firestore
          .collection('bookings')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    } catch (e) {
      print('Error fetching bookings: $e');
      return [];
    }
  }

  // Update booking status
  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating booking status: $e');
      rethrow;
    }
  }

  // Cancel booking
  Future<void> cancelBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'Đã hủy',
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error cancelling booking: $e');
      rethrow;
    }
  }

  // Get bookings for a court on a specific date
  Future<List<Map<String, dynamic>>> getCourtBookingsOnDate(
    String courtId,
    String date,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('bookings')
          .where('courtId', isEqualTo: courtId)
          .where('date', isEqualTo: date)
          .where('status', isEqualTo: 'Đã xác nhận')
          .get();

      return querySnapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    } catch (e) {
      print('Error fetching court bookings: $e');
      return [];
    }
  }

  // Delete booking
  Future<void> deleteBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).delete();
    } catch (e) {
      print('Error deleting booking: $e');
      rethrow;
    }
  }
}
