
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
      // Save to Firestore
      final bookingId = await _bookingRepository.createBooking(booking);
      
      // Add ID to booking data
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
      final bookings = await _bookingRepository.getUserBookings(userId);
      state = bookings;
    } catch (e) {
      print('Error loading bookings: $e');
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

  // Cancel booking
  Future<void> cancelBooking(String bookingId) async {
    try {
      await _bookingRepository.cancelBooking(bookingId);
      
      // Update local state
      final updatedBookings = state.map((booking) {
        if (booking['id'] == bookingId) {
          return {
            ...booking,
            'status': 'Đã hủy',
          };
        }
        return booking;
      }).toList();
      state = updatedBookings;
    } catch (e) {
      print('Error cancelling booking: $e');
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
          return {
            ...booking,
            'status': newStatus,
          };
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
}

final bookingsProvider =
    StateNotifierProvider<BookingsNotifier, List<Map<String, dynamic>>>((ref) {
  final bookingRepository = ref.watch(bookingRepositoryProvider);
  return BookingsNotifier(bookingRepository);
});
