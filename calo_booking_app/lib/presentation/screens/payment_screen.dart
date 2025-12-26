import 'dart:async';
import 'package:calo_booking_app/data/models/court_model.dart';
import 'package:calo_booking_app/data/models/user_model.dart';
import 'package:calo_booking_app/presentation/screens/home_screen.dart';
import 'package:calo_booking_app/presentation/widgets/booking_type_sheet.dart';
import 'package:calo_booking_app/presentation/widgets/booking_target_sheet.dart';
import 'package:calo_booking_app/presentation/viewmodels/bookings_viewmodel.dart';
import 'package:calo_booking_app/presentation/viewmodels/auth_viewmodel.dart';
import 'package:calo_booking_app/presentation/viewmodels/user_viewmodel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final CourtModel court;
  final DateTime selectedDate;
  final Set<String> selectedSlots;
  final BookingType bookingType;
  final CustomerType customerType;
  final UserModel? user;
  final String orderId;
  final int totalPrice;
  final int totalMinutes;
  final List<Map<String, dynamic>>? slotDetails;
  final String? bookingId; // Draft booking ID to update

  const PaymentScreen({
    super.key,
    required this.court,
    required this.selectedDate,
    required this.selectedSlots,
    required this.bookingType,
    required this.customerType,
    this.user,
    required this.orderId,
    required this.totalPrice,
    required this.totalMinutes,
    this.slotDetails,
    this.bookingId,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  late Timer _timer;
  int _remainingSeconds = 300; // 5 minutes
  bool _receiptUploaded = false; // Flag: 0 = chưa tải ảnh, 1 = đã tải ảnh

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer.cancel();
          // Auto-delete booking if receipt not uploaded after 5 minutes
          _autoDeleteBookingIfNotPaid();
        }
      });
    });
  }

  Future<void> _autoDeleteBookingIfNotPaid() async {
    // Only auto-delete if receipt is not uploaded
    if (!_receiptUploaded && widget.bookingId != null) {
      try {
        final firestore = FirebaseFirestore.instance;
        await firestore.collection('bookings').doc(widget.bookingId).delete();
        print('🗑️ Booking auto-deleted (timeout): ${widget.bookingId}');
      } catch (e) {
        print('❌ Error auto-deleting booking: $e');
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatSelectedSlots() {
    final slots = widget.selectedSlots.toList()..sort();
    if (slots.isEmpty) return '';
    return slots.join(' | ');
  }

  String _formatSlotDetails() {
    if (widget.slotDetails == null || widget.slotDetails!.isEmpty) {
      return _formatSelectedSlots();
    }

    // Nhóm các slot liên tiếp cùng sân
    Map<String, List<Map<String, dynamic>>> groupedByDay = {};

    for (var slot in widget.slotDetails!) {
      final key = slot['court'];
      if (!groupedByDay.containsKey(key)) {
        groupedByDay[key] = [];
      }
      groupedByDay[key]!.add(slot);
    }

    List<String> result = [];

    groupedByDay.forEach((court, slots) {
      // Sắp xếp theo startTime
      slots.sort(
        (a, b) => _timeToMinutes(
          a['startTime'],
        ).compareTo(_timeToMinutes(b['startTime'])),
      );

      List<MapEntry<String, String>> ranges = [];
      String rangeStart = slots[0]['startTime'];
      String rangeEnd = slots[0]['endTime'];

      for (int i = 1; i < slots.length; i++) {
        // Nếu slot tiếp theo liên tiếp (endTime của slot hiện tại = startTime của slot tiếp theo)
        if (rangeEnd == slots[i]['startTime']) {
          rangeEnd = slots[i]['endTime'];
        } else {
          // Lưu range hiện tại và bắt đầu range mới
          ranges.add(MapEntry(rangeStart, rangeEnd));
          rangeStart = slots[i]['startTime'];
          rangeEnd = slots[i]['endTime'];
        }
      }
      // Lưu range cuối cùng
      ranges.add(MapEntry(rangeStart, rangeEnd));

      // Tạo chuỗi hiển thị
      for (var range in ranges) {
        result.add('• $court: ${range.key} - ${range.value}');
      }
    });

    return result.join('\n');
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  int _calculateDepositAmount() {
    return widget.totalPrice ~/ 2;
  }

  @override
  Widget build(BuildContext context) {
    final depositAmount = _calculateDepositAmount();
    final userDocAsync = ref.watch(currentUserDocProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF016D3B),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Container(
          color: const Color(0xFFF5F5F5),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Booking Information Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCardTitle('Thông tin lịch đặt'),
                      const SizedBox(height: 16),
                      userDocAsync.when(
                        data: (userDoc) {
                          final userName = userDoc?['name'] ?? '';
                          final phoneNumber = userDoc?['phoneNumber'] ?? '';

                          return Column(
                            children: [
                              _buildInfoRow('Tên', userName, isHighlight: true),
                              _buildInfoRow(
                                'SDT',
                                phoneNumber,
                                isHighlight: true,
                              ),
                              _buildInfoRow(
                                'Mã đơn',
                                widget.orderId,
                                isHighlight: true,
                              ),
                            ],
                          );
                        },
                        loading: () => Column(
                          children: [
                            _buildInfoRow(
                              'Tên',
                              'Đang tải...',
                              isHighlight: true,
                            ),
                            _buildInfoRow(
                              'SDT',
                              'Đang tải...',
                              isHighlight: true,
                            ),
                            _buildInfoRow(
                              'Mã đơn',
                              widget.orderId,
                              isHighlight: true,
                            ),
                          ],
                        ),
                        error: (_, __) => Column(
                          children: [
                            _buildInfoRow(
                              'Tên',
                              'Lỗi tải dữ liệu',
                              isHighlight: true,
                            ),
                            _buildInfoRow(
                              'SDT',
                              'Lỗi tải dữ liệu',
                              isHighlight: true,
                            ),
                            _buildInfoRow(
                              'Mã đơn',
                              widget.orderId,
                              isHighlight: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow('Chi tiết đơn', ''),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat(
                                'dd/MM/yyyy',
                              ).format(widget.selectedDate),
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatSlotDetails(),
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tổng: ${widget.totalMinutes} phút',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Tổng đơn',
                        '${widget.totalPrice.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')} đ',
                        isHighlight: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bank Account Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCardTitle('1. Tài khoản ngân hàng'),
                      const SizedBox(height: 16),
                      _buildBankInfo('Tên tài khoản', 'Truong Hai Trieu'),
                      _buildBankInfo('Số tài khoản', '8844484848'),
                      _buildBankInfo('Ngân hàng', 'BIDV'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Payment Notice Card
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  border: Border.all(color: const Color(0xFF016D3B), width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vui lòng chuyển khoản ${depositAmount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')} đ và gửi ảnh vào ở bên dưới để hoàn tất đặt lịch!',
                      style: const TextStyle(
                        color: Color(0xFF016D3B),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sau khi gửi ảnh, vui lòng kiểm tra trạng thái lịch đặt tại tab "Tài khoản" khi chủ sân xác nhận đơn.',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Countdown Timer
              Center(
                child: Column(
                  children: [
                    Text(
                      'Đơn của bạn còn được giữ trong:',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(_remainingSeconds),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _remainingSeconds <= 60
                            ? Colors.red
                            : const Color(0xFF016D3B),
                      ),
                    ),
                    if (_remainingSeconds <= 60)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          _receiptUploaded
                              ? 'Bạn đã tải ảnh, có thể xác nhận đặt'
                              : 'Vui lòng tải ảnh thanh toán để xác nhận!',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _receiptUploaded ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Receipt Upload Area
              GestureDetector(
                onTap: () {
                  setState(() {
                    _receiptUploaded = !_receiptUploaded;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: _receiptUploaded
                        ? const Color(0xFFE8F5E9)
                        : Colors.white,
                    border: Border.all(
                      color: _receiptUploaded
                          ? const Color(0xFF016D3B)
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          _receiptUploaded ? Icons.check_circle : Icons.add,
                          size: 40,
                          color: _receiptUploaded
                              ? const Color(0xFF016D3B)
                              : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _receiptUploaded
                              ? 'Đã tải hình thanh toán'
                              : 'Nhân vào để tải hình thanh toán (*)',
                          style: TextStyle(
                            color: _receiptUploaded
                                ? const Color(0xFF016D3B)
                                : Colors.grey.shade600,
                            fontSize: 13,
                            fontWeight: _receiptUploaded
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    // Get current user ID and email
                    final authRepository = ref.read(authRepositoryProvider);
                    final userId = authRepository.currentUserId;
                    final userEmail = authRepository.currentUserEmail;

                    if (userId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng đăng nhập')),
                      );
                      return;
                    }

                    try {
                      // If booking ID exists (draft booking), update it
                      if (widget.bookingId != null) {
                        final firestore = FirebaseFirestore.instance;
                        await firestore
                            .collection('bookings')
                            .doc(widget.bookingId)
                            .update({
                              'userId': userId,
                              'courtId': widget.court.id,
                              'status': _receiptUploaded
                                  ? 'Đã thanh toán'
                                  : 'Chưa thanh toán',
                              'userName': userDocAsync.value?['name'] ?? '',
                              'userPhone':
                                  userDocAsync.value?['phoneNumber'] ?? '',
                              'email': userEmail ?? '',
                              'depositPaid': _calculateDepositAmount(),
                              'receiptUploaded':
                                  _receiptUploaded, // Flag for staff to verify
                              'updatedAt': FieldValue.serverTimestamp(),
                            });

                        print(
                          '✅ Booking confirmed (updated): ${widget.bookingId}',
                        );
                      } else {
                        // Fallback: Create new booking if no draft ID
                        final newBooking = {
                          'userId': userId,
                          'courtId': widget.court.id,
                          'courtName': widget.court.name,
                          'status': _receiptUploaded
                              ? 'Đã thanh toán'
                              : 'Chưa thanh toán',
                          'slots': widget.slotDetails ?? [],
                          'date': DateFormat(
                            'dd/MM/yyyy',
                          ).format(widget.selectedDate),
                          'address': widget.court.location,
                          'totalDuration': widget.totalMinutes,
                          'totalPrice': widget.totalPrice,
                          'depositPaid': _calculateDepositAmount(),
                          'orderId': widget.orderId,
                          'customerType': widget.customerType.toString(),
                          'bookingType': widget.bookingType.toString(),
                          'userName': userDocAsync.value?['name'] ?? '',
                          'userPhone': userDocAsync.value?['phoneNumber'] ?? '',
                          'email': userEmail ?? '',
                          'receiptUploaded':
                              _receiptUploaded, // Flag for staff to verify
                        };

                        ref
                            .read(bookingsProvider.notifier)
                            .addBooking(newBooking);
                        print('💾 Booking created (new)');
                      }

                      // Show success dialog
                      if (context.mounted) {
                        _showSuccessDialog(context);
                      }
                    } catch (e) {
                      print('❌ Error confirming booking: $e');
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4A820),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'XÁC NHẬN ĐẶT',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                color: isHighlight ? const Color(0xFF016D3B) : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFF0F9F7),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDCC),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_circle,
                    size: 60,
                    color: Color(0xFFD4A820),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Success Title
              const Text(
                'Đặt sân thành công!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Booking Details
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ngày: ${DateFormat('dd/MM/yyyy').format(widget.selectedDate)}',
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sân được chọn:',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatSlotDetails(),
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Close Button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF016D3B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Đóng',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
