import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:calo_booking_app/data/repositories/booking_repository_parallel.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Ví dụ ViewModel sử dụng Concurrency & Parallelism
///
/// Patterns:
/// 1. Parallel loading trong initState
/// 2. Stream-based state management
/// 3. Batch operations

// Provider cho parallel repository
final bookingRepoParallelProvider = Provider((ref) {
  return BookingRepositoryParallel(FirebaseFirestore.instance);
});

// ============================================================
// 1. STATE CLASS với loading states
// ============================================================

class DashboardState {
  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> bookings;
  final List<Map<String, dynamic>> courts;
  final int unreadNotifications;

  const DashboardState({
    this.isLoading = false,
    this.error,
    this.bookings = const [],
    this.courts = const [],
    this.unreadNotifications = 0,
  });

  DashboardState copyWith({
    bool? isLoading,
    String? error,
    List<Map<String, dynamic>>? bookings,
    List<Map<String, dynamic>>? courts,
    int? unreadNotifications,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      bookings: bookings ?? this.bookings,
      courts: courts ?? this.courts,
      unreadNotifications: unreadNotifications ?? this.unreadNotifications,
    );
  }
}

// ============================================================
// 2. VIEWMODEL với Parallel Loading
// ============================================================

class DashboardViewModel extends StateNotifier<DashboardState> {
  final BookingRepositoryParallel _repository;

  DashboardViewModel(this._repository) : super(const DashboardState());

  /// Load tất cả data cần thiết cho dashboard SONG SONG
  /// Thay vì load tuần tự, load cùng lúc để tiết kiệm thời gian
  Future<void> loadDashboardParallel(String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 🚀 PARALLEL: Load nhiều data sources cùng lúc
      final results = await Future.wait([
        _loadUserBookings(userId),
        _loadActiveCourts(),
        _loadUnreadNotifications(userId),
      ]);

      state = state.copyWith(
        isLoading: false,
        bookings: results[0] as List<Map<String, dynamic>>,
        courts: results[1] as List<Map<String, dynamic>>,
        unreadNotifications: results[2] as int,
      );

      print('✅ Dashboard loaded in parallel!');
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      print('❌ Error loading dashboard: $e');
    }
  }

  /// Load với fallback - nếu một request fail, vẫn hiển thị data khác
  Future<void> loadDashboardWithFallback(String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    // Chạy song song nhưng handle lỗi riêng cho từng request
    final results = await Future.wait([
      _loadUserBookings(userId).catchError((_) => <Map<String, dynamic>>[]),
      _loadActiveCourts().catchError((_) => <Map<String, dynamic>>[]),
      _loadUnreadNotifications(userId).catchError((_) => 0),
    ]);

    state = state.copyWith(
      isLoading: false,
      bookings: results[0] as List<Map<String, dynamic>>,
      courts: results[1] as List<Map<String, dynamic>>,
      unreadNotifications: results[2] as int,
    );
  }

  // Private helper methods
  Future<List<Map<String, dynamic>>> _loadUserBookings(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .get();

    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<List<Map<String, dynamic>>> _loadActiveCourts() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('courts')
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<int> _loadUnreadNotifications(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    return snapshot.docs.length;
  }

  /// Batch cancel nhiều bookings
  Future<void> batchCancelBookings(List<String> bookingIds) async {
    state = state.copyWith(isLoading: true);

    try {
      await _repository.batchCancelBookings(bookingIds);

      // Update local state
      final updatedBookings = state.bookings.map((booking) {
        if (bookingIds.contains(booking['id'])) {
          return {...booking, 'status': 'Đã hủy'};
        }
        return booking;
      }).toList();

      state = state.copyWith(isLoading: false, bookings: updatedBookings);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// Provider
final dashboardViewModelProvider =
    StateNotifierProvider<DashboardViewModel, DashboardState>((ref) {
      final repository = ref.watch(bookingRepoParallelProvider);
      return DashboardViewModel(repository);
    });

// ============================================================
// 3. STREAM-BASED PROVIDER cho real-time updates
// ============================================================

/// Provider tự động update khi có thay đổi trong Firestore
final userBookingsStreamProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, userId) {
      return FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => {'id': doc.id, ...doc.data()})
                .toList(),
          );
    });

/// Combined stream cho dashboard
final dashboardStreamProvider =
    StreamProvider.family<Map<String, dynamic>, String>((ref, userId) {
      final bookingsStream = FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .limit(5)
          .snapshots();

      final notificationsStream = FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .snapshots();

      // Combine streams
      return bookingsStream.asyncMap((bookingsSnap) async {
        final notificationsSnap = await notificationsStream.first;

        return {
          'recentBookings': bookingsSnap.docs.map((d) => d.data()).toList(),
          'unreadCount': notificationsSnap.docs.length,
        };
      });
    });
