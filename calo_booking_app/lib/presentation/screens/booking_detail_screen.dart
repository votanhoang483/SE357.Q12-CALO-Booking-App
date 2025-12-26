import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calo_booking_app/presentation/viewmodels/bookings_viewmodel.dart';

class BookingDetailScreen extends ConsumerWidget {
  final Map<String, dynamic> booking;

  const BookingDetailScreen({
    super.key,
    required this.booking,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _getStatusColor(booking['status']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết đặt lịch'),
        backgroundColor: const Color(0xFF1B7A6B),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trạng thái',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      border: Border.all(
                        color: statusColor,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      booking['status'],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Court Information Section
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sân cầu lông',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    booking['courtName'],
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    booking['address'],
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Booking Details Section
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chi tiết đặt lịch',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Thời gian:', _formatSlotDetails()),
                  const SizedBox(height: 12),
                  _buildDetailRow('Ngày:', booking['date']),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Loại khách hàng:',
                    _getCustomerTypeLabel(booking['customerType'] ?? 'student'),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Loại đặt:',
                    _getBookingTypeLabel(booking['bookingType'] ?? 'dateBooking'),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Customer Information Section
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin khách hàng',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Tên:', booking['userName'] ?? ''),
                  const SizedBox(height: 12),
                  _buildDetailRow('Số điện thoại:', booking['userPhone'] ?? ''),
                  const SizedBox(height: 12),
                  _buildDetailRow('Email:', booking['email'] ?? ''),
                ],
              ),
            ),

            const Divider(height: 1),

            // Price Section
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Giá tiền',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPriceRow(
                    'Giá sân:',
                    _formatPrice(booking['totalPrice'] ?? 0),
                  ),
                  const SizedBox(height: 8),
                  _buildPriceRow('Giảm giá:', '-0 đ'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey, width: 0.5),
                        bottom: BorderSide(color: Colors.grey, width: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tổng cộng:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatPrice(booking['totalPrice'] ?? 0),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPriceRow(
                    'Đã thanh toán:',
                    _formatPrice(booking['depositPaid'] ?? 0),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            if (booking['status'] == 'Đã xác nhận')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _showCancelDialog(context, ref);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Hủy đặt lịch',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1B7A6B),
                          side: const BorderSide(
                            color: Color(0xFF1B7A6B),
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Liên hệ hỗ trợ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1B7A6B),
                      side: const BorderSide(
                        color: Color(0xFF1B7A6B),
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Liên hệ hỗ trợ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy đặt lịch'),
        content: const Text('Bạn có chắc chắn muốn hủy đặt lịch này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                // Cancel booking in Firestore
                if (booking['id'] != null) {
                  await ref
                      .read(bookingsProvider.notifier)
                      .cancelBooking(booking['id']);
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã hủy đặt lịch thành công'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi: $e'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Hủy',
              style: TextStyle(color: Colors.red),
            ),
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
      default:
        return Colors.grey;
    }
  }

  String _getCustomerTypeLabel(String customerType) {
    switch (customerType) {
      case 'student':
        return 'Học sinh - sinh viên';
      case 'adult':
        return 'Người lớn';
      case 'group':
        return 'Nhóm';
      default:
        return customerType;
    }
  }

  String _getBookingTypeLabel(String bookingType) {
    switch (bookingType) {
      case 'dateBooking':
        return 'Cá nhân';
      case 'groupBooking':
        return 'Nhóm';
      default:
        return bookingType;
    }
  }

  String _formatSlotDetails() {
    final slots = booking['slots'] as List<dynamic>?;
    if (slots == null || slots.isEmpty) {
      return 'Chưa có thông tin';
    }

    // Convert to Map if needed and group by court
    Map<String, List<Map<String, dynamic>>> groupedByDay = {};
    
    for (var slot in slots) {
      final slotMap = Map<String, dynamic>.from(slot as Map);
      final key = slotMap['court'];
      if (!groupedByDay.containsKey(key)) {
        groupedByDay[key] = [];
      }
      groupedByDay[key]!.add(slotMap);
    }

    List<String> result = [];
    
    groupedByDay.forEach((court, slotList) {
      // Sort by startTime
      slotList.sort((a, b) => _timeToMinutes(a['startTime'] as String)
          .compareTo(_timeToMinutes(b['startTime'] as String)));
      
      List<MapEntry<String, String>> ranges = [];
      String rangeStart = slotList[0]['startTime'] as String;
      String rangeEnd = slotList[0]['endTime'] as String;
      
      for (int i = 1; i < slotList.length; i++) {
        // If next slot is consecutive
        if (rangeEnd == slotList[i]['startTime']) {
          rangeEnd = slotList[i]['endTime'] as String;
        } else {
          // Save current range and start new one
          ranges.add(MapEntry(rangeStart, rangeEnd));
          rangeStart = slotList[i]['startTime'] as String;
          rangeEnd = slotList[i]['endTime'] as String;
        }
      }
      // Save last range
      ranges.add(MapEntry(rangeStart, rangeEnd));
      
      // Create display string
      for (var range in ranges) {
        result.add('$court: ${range.key} - ${range.value}');
      }
    });

    return result.join('\n');
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String _formatPrice(dynamic price) {
    final amount = price is int ? price : (price as num?)?.toInt() ?? 0;
    return '${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')} đ';
  }
}