import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:calo_booking_app/data/repositories/booking_repository.dart';
import 'package:flutter_riverpod/legacy.dart';

// Provider for BookingRepository
final bookingRepositoryProvider = Provider((ref) {
  return BookingRepository(FirebaseFirestore.instance);
});

class BookingsNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final BookingRepository _bookingRepository;

  BookingsNotifier(this._bookingRepository) : super([]);

  // Add booking to Firestore
  Future<void> addBooking(Map<String, dynamic> booking) async {
    try {
      // Remove statusColor before saving (it's only for UI)
      booking.remove('statusColor');

      // Save to Firestore
      final bookingId = await _bookingRepository.createBooking(booking);

      // Add ID to booking data for local state
      booking['id'] = bookingId;

      // Update local state
      state = [...state, booking];
    } catch (e) {
      print('Error adding booking: $e');
      rethrow;
    }
  }

  // Load user bookings from Firestore
  Future<void> loadUserBookings(String userId) async {
    try {
      print('📋 loadUserBookings called for userId: $userId');
      final bookings = await _bookingRepository.getUserBookings(userId);
      print('📊 Setting state with ${bookings.length} bookings');
      state = bookings;
    } catch (e) {
      print('❌ Error loading bookings: $e');
      rethrow;
    }
  }

  // Load all bookings from Firestore
  Future<void> loadAllBookings() async {
    try {
      final bookings = await _bookingRepository.getAllBookings();
      state = bookings;
    } catch (e) {
      print('Error loading all bookings: $e');
      rethrow;
    }
  }

  // Load bookings for a specific court (for staff)
  Future<void> loadCourtBookings(String courtId) async {
    try {
      print('📋 Loading bookings for courtId: $courtId');
      final bookings = await _bookingRepository.getCourtBookings(courtId);
      print('📊 Loaded ${bookings.length} bookings for court: $courtId');
      state = bookings;
    } catch (e) {
      print('❌ Error loading court bookings: $e');
      rethrow;
    }
  }

  // Cancel booking
  Future<void> cancelBooking(String bookingId) async {
    try {
      await _bookingRepository.cancelBooking(bookingId);

      // Update local state
      final updatedBookings = state.map((booking) {
        if (booking['id'] == bookingId) {
          return {...booking, 'status': 'Đã hủy'};
        }
        return booking;
      }).toList();
      state = updatedBookings;
    } catch (e) {
      print('Error cancelling booking: $e');
      rethrow;
    }
  }

  // Request cancellation (for paid bookings)
  Future<void> requestCancellation(String bookingId) async {
    try {
      await _bookingRepository.requestCancellation(bookingId);

      // Update local state
      final updatedBookings = state.map((booking) {
        if (booking['id'] == bookingId) {
          return {...booking, 'status': 'Yêu cầu hủy'};
        }
        return booking;
      }).toList();
      state = updatedBookings;
    } catch (e) {
      print('Error requesting cancellation: $e');
      rethrow;
    }
  }

  // Update booking status
  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    try {
      await _bookingRepository.updateBookingStatus(bookingId, newStatus);

      // Update local state
      final updatedBookings = state.map((booking) {
        if (booking['id'] == bookingId) {
          return {...booking, 'status': newStatus};
        }
        return booking;
      }).toList();
      state = updatedBookings;
    } catch (e) {
      print('Error updating booking status: $e');
      rethrow;
    }
  }

  // Delete booking
  Future<void> deleteBooking(String bookingId) async {
    try {
      await _bookingRepository.deleteBooking(bookingId);

      // Remove from local state
      state = state.where((booking) => booking['id'] != bookingId).toList();
    } catch (e) {
      print('Error deleting booking: $e');
      rethrow;
    }
  }

  List<Map<String, dynamic>> getAllBookings() {
    return state;
  }

  // ============================================================
  // TRANSACTION METHODS - Đảm bảo data consistency
  // ============================================================

  /// Tạo booking với Transaction để tránh double-booking
  Future<String> createBookingWithTransaction({
    required String courtId,
    required String date,
    required List<Map<String, dynamic>> slots,
    required Map<String, dynamic> bookingData,
  }) async {
    try {
      final bookingId = await _bookingRepository.createBookingWithTransaction(
        courtId: courtId,
        date: date,
        slots: slots,
        bookingData: bookingData,
      );

      // Reload bookings để cập nhật state
      if (bookingData['userId'] != null) {
        await loadUserBookings(bookingData['userId']);
      }

      return bookingId;
    } catch (e) {
      print('Error creating booking with transaction: $e');
      rethrow;
    }
  }

  /// Xác nhận thanh toán với Transaction
  Future<bool> confirmPaymentWithTransaction({
    required String bookingId,
    required double amountPaid,
    required String paymentMethod,
  }) async {
    try {
      final success = await _bookingRepository.confirmPaymentWithTransaction(
        bookingId: bookingId,
        amountPaid: amountPaid,
        paymentMethod: paymentMethod,
      );

      if (success) {
        // Update local state
        final updatedBookings = state.map((booking) {
          if (booking['id'] == bookingId) {
            return {
              ...booking,
              'status': 'Đã thanh toán',
              'paymentStatus': 'paid',
              'amountPaid': amountPaid,
            };
          }
          return booking;
        }).toList();
        state = updatedBookings;
      }

      return success;
    } catch (e) {
      print('Error confirming payment: $e');
      rethrow;
    }
  }

  /// Hủy booking với Transaction (có tính refund)
  Future<Map<String, dynamic>> cancelBookingWithTransaction({
    required String bookingId,
    required String reason,
  }) async {
    try {
      final result = await _bookingRepository.cancelBookingWithTransaction(
        bookingId: bookingId,
        reason: reason,
      );

      if (result['success'] == true) {
        // Update local state
        final updatedBookings = state.map((booking) {
          if (booking['id'] == bookingId) {
            return {
              ...booking,
              'status': 'Đã hủy',
              'refundAmount': result['refundAmount'],
              'refundStatus': result['refundStatus'],
            };
          }
          return booking;
        }).toList();
        state = updatedBookings;
      }

      return result;
    } catch (e) {
      print('Error cancelling booking with transaction: $e');
      rethrow;
    }
  }

  /// Transfer booking với Transaction
  Future<bool> transferBookingWithTransaction({
    required String bookingId,
    required String newUserId,
    required String newUserName,
    required String newUserPhone,
  }) async {
    try {
      final success = await _bookingRepository.transferBookingWithTransaction(
        bookingId: bookingId,
        newUserId: newUserId,
        newUserName: newUserName,
        newUserPhone: newUserPhone,
      );

      if (success) {
        // Remove from current user's list (transferred to another user)
        state = state.where((booking) => booking['id'] != bookingId).toList();
      }

      return success;
    } catch (e) {
      print('Error transferring booking: $e');
      rethrow;
    }
  }
}

final bookingsProvider =
    StateNotifierProvider<BookingsNotifier, List<Map<String, dynamic>>>((ref) {
      final bookingRepository = ref.watch(bookingRepositoryProvider);
      return BookingsNotifier(bookingRepository);
    });

// ============================================================
// STREAM PROVIDER - Real-time updates (Concurrency Pattern)
// ============================================================

/// Stream provider để lắng nghe bookings của một court theo thời gian thực
/// Khi có booking mới, UI sẽ tự động cập nhật mà không cần reload
final courtBookingsStreamProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, courtId) {
      final firestore = FirebaseFirestore.instance;

      print('🔄 [STREAM] Starting real-time listener for court: $courtId');

      return firestore
          .collection('bookings')
          .where('courtId', isEqualTo: courtId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            print(
              '📡 [STREAM] Received ${snapshot.docs.length} bookings update',
            );
            return snapshot.docs.map((doc) {
              return {'id': doc.id, ...doc.data()};
            }).toList();
          });
    });
