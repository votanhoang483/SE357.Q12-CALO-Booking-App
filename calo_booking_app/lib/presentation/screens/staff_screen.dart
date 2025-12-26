import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calo_booking_app/presentation/viewmodels/bookings_viewmodel.dart';
import 'package:calo_booking_app/presentation/viewmodels/auth_viewmodel.dart';
import 'package:calo_booking_app/presentation/viewmodels/user_viewmodel.dart';
import 'package:calo_booking_app/presentation/screens/login_screen.dart';

class StaffScreen extends ConsumerStatefulWidget {
  const StaffScreen({super.key});

  @override
  ConsumerState<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends ConsumerState<StaffScreen> {
  @override
  void initState() {
    super.initState();
    // Load all bookings on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingsProvider.notifier).loadAllBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingsProvider);
    final screenContext = context;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý đặt lịch'),
        backgroundColor: const Color(0xFF1B7A6B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(screenContext),
          ),
        ],
      ),
      body: _buildBody(bookingsAsync),
    );
  }

  Widget _buildBody(List<Map<String, dynamic>> bookings) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group bookings by status
            _buildBookingsContent(bookings),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsContent(List<Map<String, dynamic>> bookings) {
    // Group bookings by status
    final pendingPayment = bookings
        .where((b) => b['status'] == 'Chưa thanh toán')
        .toList();
    final paid = bookings.where((b) => b['status'] == 'Đã thanh toán').toList();
    final confirmed = bookings
        .where((b) => b['status'] == 'Đã xác nhận')
        .toList();
    final cancelRequests = bookings
        .where((b) => b['status'] == 'Yêu cầu hủy')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pending Payment Section
        _buildSection(
          title: 'Chưa thanh toán (${pendingPayment.length})',
          bookings: pendingPayment,
          onConfirm: null, // Can only delete pending
          onDelete: (bookingId) => _deleteBooking(bookingId),
        ),
        const SizedBox(height: 24),

        // Paid but not confirmed
        _buildSection(
          title: 'Đã thanh toán (${paid.length})',
          bookings: paid,
          onConfirm: (bookingId) => _confirmBooking(bookingId),
          onDelete: null,
        ),
        const SizedBox(height: 24),

        // Confirmed
        _buildSection(
          title: 'Đã xác nhận (${confirmed.length})',
          bookings: confirmed,
          onConfirm: null,
          onDelete: null,
        ),
        const SizedBox(height: 24),

        // Cancellation Requests
        if (cancelRequests.isNotEmpty) ...[
          _buildSection(
            title: 'Yêu cầu hủy (${cancelRequests.length})',
            bookings: cancelRequests,
            onConfirm: (bookingId) => _approveCancellation(bookingId),
            onDelete: (bookingId) => _rejectCancellation(bookingId),
          ),
        ],
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Map<String, dynamic>> bookings,
    required Function(String)? onConfirm,
    required Function(String)? onDelete,
  }) {
    if (bookings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B7A6B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Không có booking nào',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1B7A6B).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B7A6B),
              ),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: bookings.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.grey.shade200),
            itemBuilder: (_, index) {
              final booking = bookings[index];
              return _buildBookingCard(
                booking,
                onConfirm: onConfirm,
                onDelete: onDelete,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(
    Map<String, dynamic> booking, {
    required Function(String)? onConfirm,
    required Function(String)? onDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking['courtName'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${booking['date']} | ${booking['userName']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SĐT: ${booking['userPhone']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        booking['status'],
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      booking['status'],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(booking['status']),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${booking['totalPrice']} đ',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (onConfirm != null || onDelete != null)
            Row(
              children: [
                if (onConfirm != null)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => onConfirm(booking['id'] as String),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text(
                        'Xác nhận',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ),
                if (onConfirm != null && onDelete != null)
                  const SizedBox(width: 8),
                if (onDelete != null)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => onDelete(booking['id'] as String),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text(
                        booking['status'] == 'Yêu cầu hủy'
                            ? 'Duyệt hủy'
                            : 'Hủy',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Đã xác nhận':
        return Colors.green;
      case 'Đã thanh toán':
        return Colors.blue;
      case 'Chưa thanh toán':
        return Colors.orange;
      case 'Yêu cầu hủy':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _confirmBooking(String bookingId) async {
    try {
      print('✅ Confirming booking: $bookingId');
      await ref
          .read(bookingsProvider.notifier)
          .updateBookingStatus(bookingId, 'Đã xác nhận');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã xác nhận booking')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Future<void> _deleteBooking(String bookingId) async {
    try {
      print('🗑️ Deleting booking: $bookingId');
      await ref.read(bookingsProvider.notifier).cancelBooking(bookingId);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã xóa booking')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Future<void> _approveCancellation(String bookingId) async {
    try {
      print('✅ Approving cancellation: $bookingId');
      await ref
          .read(bookingsProvider.notifier)
          .updateBookingStatus(bookingId, 'Đã hủy');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã duyệt hủy booking')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Future<void> _rejectCancellation(String bookingId) async {
    try {
      print('❌ Rejecting cancellation: $bookingId');
      await ref
          .read(bookingsProvider.notifier)
          .updateBookingStatus(bookingId, 'Đã xác nhận');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã từ chối hủy booking')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  void _showLogoutDialog(BuildContext screenContext) {
    showDialog(
      context: screenContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              try {
                print('🔓 Logging out...');
                await ref.read(authProvider.notifier).logout();

                print('✅ Logout successful!');

                if (screenContext.mounted) {
                  ScaffoldMessenger.of(screenContext).showSnackBar(
                    const SnackBar(
                      content: Text('Đã đăng xuất thành công'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }

                // Don't navigate - let authStateProvider emit null
                // MyApp will rebuild automatically and show LoginScreen
                print(
                  '🔄 AuthStateProvider emitted null, MyApp will rebuild...',
                );
              } catch (e) {
                print('❌ Logout error: $e');
                if (screenContext.mounted) {
                  ScaffoldMessenger.of(
                    screenContext,
                  ).showSnackBar(SnackBar(content: Text('Lỗi đăng xuất: $e')));
                }
              }
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
