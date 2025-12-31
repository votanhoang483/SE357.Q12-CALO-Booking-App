import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calo_booking_app/presentation/screens/booking_detail_screen.dart';
import 'package:calo_booking_app/presentation/viewmodels/bookings_viewmodel.dart';
import 'package:calo_booking_app/presentation/viewmodels/auth_viewmodel.dart';

class BookedScheduleScreen extends ConsumerStatefulWidget {
  const BookedScheduleScreen({super.key});

  @override
  ConsumerState<BookedScheduleScreen> createState() =>
      _BookedScheduleScreenState();
}

class _BookedScheduleScreenState extends ConsumerState<BookedScheduleScreen> {
  @override
  void initState() {
    super.initState();
    // Load user bookings from Firestore when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authRepository = ref.read(authRepositoryProvider);
      final userId = authRepository.currentUserId;

      print('🔍 BookedScheduleScreen - userId: $userId');

      if (userId != null) {
        print('📥 Loading bookings for userId: $userId');
        ref.read(bookingsProvider.notifier).loadUserBookings(userId);
      } else {
        print('❌ No userId found!');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookings = ref.watch(bookingsProvider);

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          'Danh sách đặt lịch',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF016D3B),
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: bookings.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_month,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bạn chưa có đặt lịch nào',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // View All Button
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: const Text('Xem tất cả'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF016D3B),
                          side: const BorderSide(
                            color: Color(0xFF016D3B),
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bookings List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: bookings.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: Colors.grey),
                    itemBuilder: (context, index) {
                      final booking = bookings[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  BookingDetailScreen(booking: booking),
                            ),
                          );
                        },
                        child: _buildBookingCard(booking),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Court Name and Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  booking['courtName'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(booking['status']).withOpacity(0.1),
                  border: Border.all(
                    color: _getStatusColor(booking['status']),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  booking['status'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _getStatusColor(booking['status']),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Court Details
          Text(
            'Chi tiết: ${_formatSlotDetails(booking)} | Ngày ${booking['date']}',
            style: TextStyle(
              fontSize: 13,
              color: const Color(0xFF016D3B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          // Address
          Text(
            'Địa chỉ: ${booking['address']}',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Đã xác nhận':
        return Colors.green;
      case 'Đã hủy':
        return Colors.red;
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

  /// Format chi tiết slot: Sân X | HH:mm - HH:mm
  String _formatSlotDetails(Map<String, dynamic> booking) {
    final slots = booking['slots'] as List<dynamic>?;

    if (slots == null || slots.isEmpty) {
      return 'Không có thông tin';
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
      return '$court ($startTime - $endTime)';
    } else if (startTime != null) {
      return '$court ($startTime)';
    }

    return '$court';
  }
}
