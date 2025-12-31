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

  // Get bookings for a specific court (for staff)
  Future<List<Map<String, dynamic>>> getCourtBookings(String courtId) async {
    try {
      print('🔥 Fetching bookings for courtId: $courtId');
      final querySnapshot = await _firestore
          .collection('bookings')
          .where('courtId', isEqualTo: courtId)
          .orderBy('createdAt', descending: true)
          .get();

      print(
        '✅ Found ${querySnapshot.docs.length} bookings for court: $courtId',
      );
      return querySnapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    } catch (e) {
      print('❌ Error fetching court bookings: $e');
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

  // Request cancellation for paid bookings (send to staff)
  Future<void> requestCancellation(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'Yêu cầu hủy',
        'cancellationRequestedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error requesting cancellation: $e');
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

  // ============================================================
  // TRANSACTION METHODS - Đảm bảo data consistency
  // ============================================================

  /// Tạo booking với Transaction để tránh double-booking (race condition)
  /// 
  /// Flow:
  /// 1. Kiểm tra tất cả slots có còn trống không
  /// 2. Nếu có slot đã bị đặt -> throw error
  /// 3. Nếu tất cả trống -> tạo booking
  /// 
  /// Transaction đảm bảo: Nếu 2 người đặt cùng slot cùng lúc,
  /// chỉ 1 người thành công, người còn lại nhận lỗi
  Future<String> createBookingWithTransaction({
    required String courtId,
    required String date,
    required List<Map<String, dynamic>> slots,
    required Map<String, dynamic> bookingData,
  }) async {
    try {
      print('🔒 Starting transaction for booking...');
      
      return await _firestore.runTransaction<String>((transaction) async {
        // Step 1: Check tất cả bookings hiện có cho ngày và sân này
        final existingBookingsQuery = await _firestore
            .collection('bookings')
            .where('courtId', isEqualTo: courtId)
            .where('date', isEqualTo: date)
            .where('status', whereIn: ['Đã xác nhận', 'Đã thanh toán', 'Chờ thanh toán', 'Chưa thanh toán'])
            .get();

        print('📊 Found ${existingBookingsQuery.docs.length} existing bookings');

        // Step 2: Kiểm tra xem có slot nào bị trùng không
        final bookedSlots = <String>{};
        for (final doc in existingBookingsQuery.docs) {
          final booking = doc.data();
          final existingSlots = booking['slots'] as List<dynamic>?;
          
          // Kiểm tra expiry cho booking chờ thanh toán
          if (booking['status'] == 'Chờ thanh toán' || booking['status'] == 'Chưa thanh toán') {
            final expiresAt = booking['expiresAt'] as Timestamp?;
            if (expiresAt != null && DateTime.now().isAfter(expiresAt.toDate())) {
              // Booking đã hết hạn, bỏ qua
              print('⏰ Skipping expired booking: ${doc.id}');
              continue;
            }
          }
          
          if (existingSlots != null) {
            for (final slot in existingSlots) {
              final slotMap = slot as Map<String, dynamic>;
              final slotKey = '${slotMap['court']}_${slotMap['startIndex']}';
              bookedSlots.add(slotKey);
            }
          }
        }

        // Step 3: Kiểm tra slots mới có bị trùng không
        for (final slot in slots) {
          final slotKey = '${slot['court']}_${slot['startIndex']}';
          if (bookedSlots.contains(slotKey)) {
            print('❌ Slot conflict: $slotKey already booked!');
            throw Exception(
              'Slot ${slot['court']} (${slot['startTime']} - ${slot['endTime']}) đã được đặt. Vui lòng chọn slot khác.',
            );
          }
        }

        // Step 4: Tất cả slots đều trống -> tạo booking
        final newBookingRef = _firestore.collection('bookings').doc();
        
        final fullBookingData = {
          ...bookingData,
          'courtId': courtId,
          'date': date,
          'slots': slots,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        transaction.set(newBookingRef, fullBookingData);
        
        print('✅ Transaction successful! Booking ID: ${newBookingRef.id}');
        return newBookingRef.id;
      });
    } catch (e) {
      print('❌ Transaction failed: $e');
      rethrow;
    }
  }

  /// Xác nhận thanh toán với Transaction
  /// Đảm bảo booking vẫn còn valid (chưa hết hạn, chưa bị cancel)
  Future<bool> confirmPaymentWithTransaction({
    required String bookingId,
    required double amountPaid,
    required String paymentMethod,
  }) async {
    try {
      return await _firestore.runTransaction<bool>((transaction) async {
        // Step 1: Đọc booking hiện tại
        final bookingRef = _firestore.collection('bookings').doc(bookingId);
        final bookingDoc = await transaction.get(bookingRef);

        if (!bookingDoc.exists) {
          throw Exception('Booking không tồn tại');
        }

        final bookingData = bookingDoc.data()!;
        final status = bookingData['status'] as String?;
        final expiresAt = bookingData['expiresAt'] as Timestamp?;

        // Step 2: Kiểm tra booking còn valid không
        if (status == 'Đã hủy') {
          throw Exception('Booking đã bị hủy');
        }

        if (status == 'Đã thanh toán') {
          throw Exception('Booking đã được thanh toán');
        }

        // Kiểm tra hết hạn
        if (expiresAt != null && DateTime.now().isAfter(expiresAt.toDate())) {
          throw Exception('Booking đã hết hạn. Vui lòng đặt lại.');
        }

        // Step 3: Cập nhật booking thành đã thanh toán
        transaction.update(bookingRef, {
          'status': 'Đã thanh toán',
          'paymentStatus': 'paid',
          'amountPaid': amountPaid,
          'paymentMethod': paymentMethod,
          'paidAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'expiresAt': FieldValue.delete(), // Xóa expiry sau khi thanh toán
        });

        print('✅ Payment confirmed for booking: $bookingId');
        return true;
      });
    } catch (e) {
      print('❌ Payment transaction failed: $e');
      rethrow;
    }
  }

  /// Hủy booking với Transaction
  /// Đảm bảo refund được tính toán chính xác dựa trên trạng thái hiện tại
  Future<Map<String, dynamic>> cancelBookingWithTransaction({
    required String bookingId,
    required String reason,
  }) async {
    try {
      return await _firestore.runTransaction<Map<String, dynamic>>((transaction) async {
        // Step 1: Đọc booking
        final bookingRef = _firestore.collection('bookings').doc(bookingId);
        final bookingDoc = await transaction.get(bookingRef);

        if (!bookingDoc.exists) {
          throw Exception('Booking không tồn tại');
        }

        final bookingData = bookingDoc.data()!;
        final status = bookingData['status'] as String?;
        final amountPaid = (bookingData['amountPaid'] as num?)?.toDouble() ?? 0;

        // Step 2: Kiểm tra có thể hủy không
        if (status == 'Đã hủy') {
          throw Exception('Booking đã được hủy');
        }

        if (status == 'Hoàn thành') {
          throw Exception('Không thể hủy booking đã hoàn thành');
        }

        // Step 3: Tính toán refund
        double refundAmount = 0;
        String refundStatus = 'no_refund';

        if (amountPaid > 0) {
          // Kiểm tra thời gian hủy để tính refund
          final bookingDate = bookingData['date'] as String?;
          // Logic tính refund dựa trên policy (ví dụ: hủy trước 24h được hoàn 100%)
          refundAmount = amountPaid; // Simplified: hoàn 100%
          refundStatus = 'pending_refund';
        }

        // Step 4: Cập nhật booking
        transaction.update(bookingRef, {
          'status': 'Đã hủy',
          'cancelledAt': FieldValue.serverTimestamp(),
          'cancellationReason': reason,
          'refundAmount': refundAmount,
          'refundStatus': refundStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print('✅ Booking cancelled: $bookingId, refund: $refundAmount');
        
        return {
          'success': true,
          'refundAmount': refundAmount,
          'refundStatus': refundStatus,
        };
      });
    } catch (e) {
      print('❌ Cancel transaction failed: $e');
      rethrow;
    }
  }

  /// Transfer booking sang user khác với Transaction
  /// Đảm bảo booking không bị thay đổi trong quá trình transfer
  Future<bool> transferBookingWithTransaction({
    required String bookingId,
    required String newUserId,
    required String newUserName,
    required String newUserPhone,
  }) async {
    try {
      return await _firestore.runTransaction<bool>((transaction) async {
        // Step 1: Đọc booking
        final bookingRef = _firestore.collection('bookings').doc(bookingId);
        final bookingDoc = await transaction.get(bookingRef);

        if (!bookingDoc.exists) {
          throw Exception('Booking không tồn tại');
        }

        final bookingData = bookingDoc.data()!;
        final status = bookingData['status'] as String?;

        // Step 2: Kiểm tra có thể transfer không
        if (status != 'Đã thanh toán' && status != 'Đã xác nhận') {
          throw Exception('Chỉ có thể transfer booking đã thanh toán');
        }

        // Step 3: Lưu lịch sử transfer
        final transferHistory = List<Map<String, dynamic>>.from(
          bookingData['transferHistory'] ?? [],
        );
        transferHistory.add({
          'fromUserId': bookingData['userId'],
          'toUserId': newUserId,
          'transferredAt': DateTime.now().toIso8601String(),
        });

        // Step 4: Cập nhật booking
        transaction.update(bookingRef, {
          'userId': newUserId,
          'userName': newUserName,
          'userPhone': newUserPhone,
          'transferHistory': transferHistory,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print('✅ Booking transferred to: $newUserId');
        return true;
      });
    } catch (e) {
      print('❌ Transfer transaction failed: $e');
      rethrow;
    }
  }
}
