import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Repository với các method sử dụng Concurrency & Parallelism
///
/// Patterns được sử dụng:
/// 1. Future.wait() - Chạy nhiều queries song song
/// 2. Stream - Real-time updates
/// 3. Batch writes - Atomic multiple updates
/// 4. Transaction - Ensure data consistency
class BookingRepositoryParallel {
  final FirebaseFirestore _firestore;

  BookingRepositoryParallel(this._firestore);

  // ============================================================
  // 1. PARALLEL QUERIES - Chạy nhiều queries cùng lúc
  // ============================================================

  /// Load bookings cho nhiều courts cùng lúc (song song)
  /// Thay vì query từng court một, query tất cả cùng lúc
  Future<Map<String, List<Map<String, dynamic>>>> getBookingsForMultipleCourts(
    List<String> courtIds,
    String date,
  ) async {
    // Tạo list các Future queries
    final futures = courtIds.map((courtId) async {
      final snapshot = await _firestore
          .collection('bookings')
          .where('courtId', isEqualTo: courtId)
          .where('date', isEqualTo: date)
          .get();

      return MapEntry(
        courtId,
        snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList(),
      );
    });

    // Chạy tất cả queries song song
    final results = await Future.wait(futures);

    return Map.fromEntries(results);
  }

  /// Load dashboard data - nhiều collections cùng lúc
  Future<Map<String, dynamic>> loadDashboardData(String userId) async {
    final results = await Future.wait([
      // Query 1: User bookings
      _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .limit(10)
          .get(),

      // Query 2: Active courts
      _firestore.collection('courts').where('isActive', isEqualTo: true).get(),

      // Query 3: User info
      _firestore.collection('users').doc(userId).get(),

      // Query 4: Notifications
      _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get(),
    ]);

    return {
      'bookings': (results[0] as QuerySnapshot).docs.map((d) => d.data()).toList(),
      'courts': (results[1] as QuerySnapshot).docs.map((d) => d.data()).toList(),
      'user': (results[2] as DocumentSnapshot).data(),
      'unreadNotifications': (results[3] as QuerySnapshot).docs.length,
    };
  }

  // ============================================================
  // 2. STREAM - Real-time concurrent updates
  // ============================================================

  /// Stream để watch bookings real-time
  /// Tự động update UI khi có thay đổi
  Stream<List<Map<String, dynamic>>> watchUserBookings(String userId) {
    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  /// Combine multiple streams - watch nhiều data sources
  Stream<Map<String, dynamic>> watchDashboard(String userId) {
    final bookingsStream = _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .snapshots();

    final notificationsStream = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots();

    // Combine 2 streams
    return bookingsStream.asyncMap((bookings) async {
      final notifications = await notificationsStream.first;
      return {
        'bookings': bookings.docs.map((d) => d.data()).toList(),
        'unreadCount': notifications.docs.length,
      };
    });
  }

  // ============================================================
  // 3. BATCH WRITES - Multiple writes trong 1 operation
  // ============================================================

  /// Cancel nhiều bookings cùng lúc (atomic)
  Future<void> batchCancelBookings(List<String> bookingIds) async {
    final batch = _firestore.batch();

    for (final bookingId in bookingIds) {
      final docRef = _firestore.collection('bookings').doc(bookingId);
      batch.update(docRef, {
        'status': 'Đã hủy',
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // Commit tất cả changes cùng lúc (atomic)
    await batch.commit();
  }

  /// Update slots availability cho nhiều courts
  Future<void> batchUpdateSlotAvailability(
    Map<String, List<String>> courtSlots, // courtId -> list of slotIds
    bool isAvailable,
  ) async {
    final batch = _firestore.batch();

    courtSlots.forEach((courtId, slotIds) {
      for (final slotId in slotIds) {
        final docRef = _firestore
            .collection('courts')
            .doc(courtId)
            .collection('slots')
            .doc(slotId);

        batch.update(docRef, {'isAvailable': isAvailable});
      }
    });

    await batch.commit();
  }

  // ============================================================
  // 4. TRANSACTION - Ensure data consistency
  // ============================================================

  /// Book slot với transaction để tránh race condition
  /// Đảm bảo slot chưa được book bởi người khác
  Future<bool> bookSlotWithTransaction(
    String courtId,
    String slotId,
    String date,
    Map<String, dynamic> bookingData,
  ) async {
    try {
      return await _firestore.runTransaction<bool>((transaction) async {
        // 1. Check if slot is still available
        final slotRef = _firestore
            .collection('courts')
            .doc(courtId)
            .collection('slots')
            .doc(slotId);

        final slotDoc = await transaction.get(slotRef);

        if (!slotDoc.exists) {
          throw Exception('Slot không tồn tại');
        }

        final slotData = slotDoc.data()!;
        final bookedDates = List<String>.from(slotData['bookedDates'] ?? []);

        if (bookedDates.contains(date)) {
          throw Exception('Slot đã được đặt');
        }

        // 2. Mark slot as booked
        bookedDates.add(date);
        transaction.update(slotRef, {'bookedDates': bookedDates});

        // 3. Create booking
        final bookingRef = _firestore.collection('bookings').doc();
        transaction.set(bookingRef, {
          ...bookingData,
          'courtId': courtId,
          'slotId': slotId,
          'date': date,
          'createdAt': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } catch (e) {
      print('❌ Transaction failed: $e');
      return false;
    }
  }

  // ============================================================
  // 5. PARALLEL với TIMEOUT - Tránh blocking
  // ============================================================

  /// Load data với timeout để không block UI quá lâu
  Future<Map<String, dynamic>?> loadDataWithTimeout(String userId) async {
    try {
      return await Future.wait([
            _firestore
                .collection('bookings')
                .where('userId', isEqualTo: userId)
                .get(),
            _firestore.collection('courts').get(),
          ])
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              print('⚠️ Data loading timed out');
              throw TimeoutException('Loading took too long');
            },
          )
          .then(
            (results) => {
              'bookings': (results[0] as QuerySnapshot).docs.map((d) => d.data()).toList(),
              'courts': (results[1] as QuerySnapshot).docs.map((d) => d.data()).toList(),
            },
          );
    } catch (e) {
      print('❌ Error loading data: $e');
      return null;
    }
  }
}
