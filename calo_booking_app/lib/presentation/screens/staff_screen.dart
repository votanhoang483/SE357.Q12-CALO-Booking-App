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
  String? _courtId;

  @override
  void initState() {
    super.initState();
    // Get courtId from user document
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userDoc = await ref.read(currentUserDocProvider.future);
      if (userDoc != null && userDoc['courtId'] != null) {
        setState(() {
          _courtId = userDoc['courtId'] as String;
        });
        print('📍 Staff assigned to court: $_courtId');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userDoc = ref.watch(currentUserDocProvider);

    // Sử dụng Stream để auto-reload khi có booking mới
    // Đây là Concurrency Pattern: Real-time Stream
    final bookingsStream = _courtId != null
        ? ref.watch(courtBookingsStreamProvider(_courtId!))
        : const AsyncValue<List<Map<String, dynamic>>>.data([]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý đặt lịch'),
        backgroundColor: const Color(0xFF016D3B),
        elevation: 0,
        centerTitle: true,
      ),
      drawer: _buildDrawer(context, userDoc),
      body: bookingsStream.when(
        data: (bookings) => _buildBody(bookings),
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF016D3B)),
              SizedBox(height: 16),
              Text('Đang tải dữ liệu...'),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 16),
              Text('Lỗi: $error'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(courtBookingsStreamProvider(_courtId!)),
                child: Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(List<Map<String, dynamic>> bookings) {
    // Calculate stats
    final pendingPayment = bookings
        .where((b) => b['status'] == 'Chưa thanh toán')
        .length;
    final paid = bookings.where((b) => b['status'] == 'Đã thanh toán').length;
    final confirmed = bookings
        .where((b) => b['status'] == 'Đã xác nhận')
        .length;
    final cancelRequests = bookings
        .where((b) => b['status'] == 'Yêu cầu hủy')
        .length;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Cards
            _buildStatsRow(pendingPayment, paid, confirmed, cancelRequests),
            const SizedBox(height: 24),

            // Bookings by status
            _buildBookingsContent(bookings),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(int pending, int paid, int confirmed, int cancel) {
    return Row(
      children: [
        _buildStatCard('Chưa Thanh toán', pending.toString(), Colors.orange),
        const SizedBox(width: 12),
        _buildStatCard('Đã Thanh toán', paid.toString(), Colors.blue),
        const SizedBox(width: 12),
        _buildStatCard('Đã Xác nhận', confirmed.toString(), Colors.green),
        const SizedBox(width: 12),
        _buildStatCard('Yêu cầu hủy', cancel.toString(), Colors.red),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
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
    final cancelled = bookings.where((b) => b['status'] == 'Đã hủy').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pending Payment Section
        _buildSection(
          title: 'Chưa thanh toán (${pendingPayment.length})',
          bookings: pendingPayment,
          onConfirm: (bookingId) => _confirmPayment(bookingId),
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
          const SizedBox(height: 24),
        ],

        // Cancelled bookings
        _buildSection(
          title: 'Đã hủy (${cancelled.length})',
          bookings: cancelled,
          onConfirm: null,
          onDelete: null,
        ),
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
                color: Color(0xFF016D3B),
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
              color: const Color(0xFF016D3B).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF016D3B),
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
    return GestureDetector(
      onTap: () => _showBookingDetail(booking, onConfirm, onDelete),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: _getStatusColor(booking['status']),
                width: 4,
              ),
            ),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Padding(
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
                            _formatBookingTitle(booking),
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
                            child: Text(
                              booking['status'] == 'Chưa thanh toán'
                                  ? 'Xác nhận đã thanh toán'
                                  : 'Xác nhận',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
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
          ),
        ),
      ),
    );
  }

  /// Format tiêu đề booking: Sân X | HH:mm - HH:mm
  /// Hiển thị rõ ràng sân số mấy và khoảng thời gian
  String _formatBookingTitle(Map<String, dynamic> booking) {
    final slots = booking['slots'] as List<dynamic>?;

    if (slots == null || slots.isEmpty) {
      return 'Không có thông tin slot';
    }

    // Lấy thông tin sân
    final firstSlot = slots.first as Map<String, dynamic>;
    final court = firstSlot['court'] ?? 'N/A';

    // Tính giờ bắt đầu và kết thúc
    String? startTime;
    String? endTime;

    if (slots.length == 1) {
      // Chỉ 1 slot
      startTime = firstSlot['startTime'] as String?;
      endTime = firstSlot['endTime'] as String?;
    } else {
      // Nhiều slots liên tiếp - lấy giờ đầu và giờ cuối
      startTime = firstSlot['startTime'] as String?;
      final lastSlot = slots.last as Map<String, dynamic>;
      endTime = lastSlot['endTime'] as String?;
    }

    if (startTime != null && endTime != null) {
      return '$court | $startTime - $endTime';
    } else if (startTime != null) {
      return '$court | $startTime';
    }

    return '$court';
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

  Future<void> _confirmPayment(String bookingId) async {
    try {
      print('💳 Confirming payment: $bookingId');
      await ref
          .read(bookingsProvider.notifier)
          .updateBookingStatus(bookingId, 'Đã thanh toán');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã xác nhận thanh toán')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
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

                  // Navigate to LoginScreen after logout
                  await Future.delayed(const Duration(milliseconds: 500));
                  if (screenContext.mounted) {
                    Navigator.of(screenContext).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                }

                print('🔄 Navigated to LoginScreen');
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

  Widget _buildDrawer(
    BuildContext context,
    AsyncValue<Map<String, dynamic>?> userDoc,
  ) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // User Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Color(0xFF016D3B)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  userDoc.when(
                    data: (data) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data?['name'] ?? 'Nhân viên',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data?['email'] ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Sân: ${data?['courtId'] == 'Fd6Ud9KYE883oBPOrcw6'
                                ? 'CALO Badminton Court'
                                : data?['courtId'] == 'oxOYQHJehSC0SWmnTZMr'
                                ? 'Phoenix Badminton Court'
                                : 'N/A'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    loading: () => const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    error: (_, __) => const Text(
                      'Lỗi tải dữ liệu',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  _buildDrawerItem(
                    icon: Icons.dashboard,
                    title: 'Trang chủ',
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildDrawerItem(
                    icon: Icons.schedule,
                    title: 'Quản lý đặt lịch',
                    onTap: () => Navigator.pop(context),
                  ),
                  const Divider(height: 24),
                  _buildDrawerItem(
                    icon: Icons.person,
                    title: 'Thông tin cá nhân',
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildDrawerItem(
                    icon: Icons.settings,
                    title: 'Cài đặt',
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Logout Button
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showLogoutDialog(context);
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Đăng xuất'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF016D3B)),
      title: Text(title),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  void _showBookingDetail(
    Map<String, dynamic> booking,
    Function(String)? onConfirm,
    Function(String)? onDelete,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (bottomContext) => DraggableScrollableSheet(
        expand: false,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(20),
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking['slots'] != null &&
                                  (booking['slots'] as List).isNotEmpty
                              ? '${(booking['slots'] as List)[0]['court']} - ${(booking['slots'] as List)[0]['startTime']}'
                              : 'N/A',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              booking['status'],
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            booking['status'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(booking['status']),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(bottomContext),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Thông tin khách hàng
              _buildDetailSection('Thông tin khách hàng', [
                _buildDetailRow('Tên', booking['userName'] ?? 'N/A'),
                _buildDetailRow('Email', booking['userEmail'] ?? 'N/A'),
                _buildDetailRow('SĐT', booking['userPhone'] ?? 'N/A'),
              ]),
              const SizedBox(height: 20),

              // Chi tiết booking
              _buildDetailSection('Chi tiết đặt lịch', [
                _buildDetailRow('Ngày', booking['date'] ?? 'N/A'),
                _buildDetailRow(
                  'Giờ',
                  booking['slots'] != null &&
                          (booking['slots'] as List).isNotEmpty
                      ? '${(booking['slots'] as List)[0]['startTime']}'
                      : 'N/A',
                ),
                _buildDetailRow(
                  'Số sân',
                  booking['slots'] != null &&
                          (booking['slots'] as List).isNotEmpty
                      ? '${(booking['slots'] as List)[0]['court']}'
                      : 'N/A',
                ),
              ]),
              const SizedBox(height: 20),

              // Thanh toán
              _buildDetailSection('Thông tin thanh toán', [
                _buildDetailRow(
                  'Giá',
                  '${booking['totalPrice'] ?? 0} đ',
                  valueStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                _buildDetailRow(
                  'Hóa đơn',
                  booking['receiptUploaded'] == true
                      ? 'Đã upload'
                      : 'Chưa upload',
                  valueStyle: TextStyle(
                    fontSize: 14,
                    color: booking['receiptUploaded'] == true
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
              ]),
              const SizedBox(height: 24),

              // Action Buttons
              if (onConfirm != null || onDelete != null) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (onConfirm != null)
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(bottomContext);
                          onConfirm(booking['id'] as String);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Xác nhận thanh toán',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (onConfirm != null && onDelete != null)
                      const SizedBox(height: 12),
                    if (onDelete != null)
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(bottomContext);
                          onDelete(booking['id'] as String);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          booking['status'] == 'Yêu cầu hủy'
                              ? 'Duyệt hủy'
                              : 'Hủy booking',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF016D3B),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                Padding(padding: const EdgeInsets.all(12), child: items[i]),
                if (i < items.length - 1)
                  Divider(height: 1, color: Colors.grey.shade200),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {TextStyle? valueStyle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
        Text(
          value,
          style:
              valueStyle ??
              const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
        ),
      ],
    );
  }
}
