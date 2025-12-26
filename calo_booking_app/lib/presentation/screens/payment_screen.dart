import 'dart:async';
import 'package:calo_booking_app/data/models/court_model.dart';
import 'package:calo_booking_app/data/models/user_model.dart';
import 'package:calo_booking_app/presentation/screens/home_screen.dart';
import 'package:calo_booking_app/presentation/widgets/booking_type_sheet.dart';
import 'package:calo_booking_app/presentation/widgets/booking_target_sheet.dart';
import 'package:calo_booking_app/presentation/viewmodels/bookings_viewmodel.dart';
import 'package:calo_booking_app/presentation/viewmodels/auth_viewmodel.dart';
import 'package:calo_booking_app/presentation/viewmodels/user_viewmodel.dart';
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
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  late Timer _timer;
  int _remainingSeconds = 300; // 5 minutes

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
        }
      });
    });
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

  int _calculateDepositAmount() {
    return widget.totalPrice ~/ 2;
  }

  @override
  Widget build(BuildContext context) {
    final depositAmount = _calculateDepositAmount();
    final userDocAsync = ref.watch(currentUserDocProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán'),
        backgroundColor: const Color(0xFF1B7A6B),
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
                            const SizedBox(height: 4),
                            Text(
                              '• ${_formatSelectedSlots()}',
                              style: const TextStyle(fontSize: 13),
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
                  border: Border.all(color: const Color(0xFF1B7A6B), width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vui lòng chuyển khoản ${depositAmount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')} đ và gửi ảnh vào ở bên dưới để hoàn tất đặt lịch!',
                      style: const TextStyle(
                        color: Color(0xFF1B7A6B),
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
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B7A6B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Receipt Upload Area
              GestureDetector(
                onTap: () {
                  // TODO: Implement image picker
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chức năng tải ảnh sẽ được cập nhật'),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.add, size: 40, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'Nhân vào để tải hình thanh toán (*)',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
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
                  onPressed: () {
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

                    // Create booking object with user info
                    final newBooking = {
                      'userId': userId,
                      'courtId': widget.court.id,
                      'courtName': widget.court.name,
                      'status': 'Đã xác nhận',
                      'courts': _formatSelectedSlots(),
                      'date': DateFormat(
                        'dd/MM/yyyy',
                      ).format(widget.selectedDate),
                      'address': widget.court.location,
                      'totalPrice': widget.totalPrice,
                      'depositPaid': _calculateDepositAmount(),
                      'orderId': widget.orderId,
                      'customerType': widget.customerType.toString(),
                      'bookingType': widget.bookingType.toString(),
                      'userName': widget.user?.name ?? '',
                      'userPhone': widget.user?.phoneNumber ?? '',
                      'email': userEmail ?? '',
                    };

                    // Save booking to provider
                    ref.read(bookingsProvider.notifier).addBooking(newBooking);

                    // Show success dialog
                    _showSuccessDialog(context);
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
                color: isHighlight ? const Color(0xFF1B7A6B) : Colors.black87,
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
              Text(
                'Bạn đã đặt thành công sân ${_formatSelectedSlots()} ngày ${DateFormat('dd/MM/yyyy').format(widget.selectedDate)}',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                textAlign: TextAlign.center,
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
                    backgroundColor: const Color(0xFF1B7A6B),
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
