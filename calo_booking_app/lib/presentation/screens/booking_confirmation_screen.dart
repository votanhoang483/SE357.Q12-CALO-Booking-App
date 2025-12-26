import 'package:calo_booking_app/data/models/court_model.dart';
import 'package:calo_booking_app/data/models/user_model.dart';
import 'package:calo_booking_app/presentation/screens/payment_screen.dart';
import 'package:calo_booking_app/presentation/widgets/booking_type_sheet.dart';
import 'package:calo_booking_app/presentation/widgets/booking_target_sheet.dart';
import 'package:calo_booking_app/presentation/viewmodels/user_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class BookingConfirmationScreen extends ConsumerStatefulWidget {
  final CourtModel court;
  final DateTime selectedDate;
  final Set<String> selectedSlots;
  final BookingType bookingType;
  final CustomerType customerType;
  final UserModel? user;

  const BookingConfirmationScreen({
    super.key,
    required this.court,
    required this.selectedDate,
    required this.selectedSlots,
    required this.bookingType,
    required this.customerType,
    this.user,
  });

  @override
  ConsumerState<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState
    extends ConsumerState<BookingConfirmationScreen> {

  int _calculateTotalHours() {
    return widget.selectedSlots.length ~/ 2; // Mỗi slot 30 phút
  }

  int _calculateTotalPrice() {
    return _calculateTotalHours() * widget.court.pricePerHour;
  }

  String _formatSelectedSlots() {
    final slots = widget.selectedSlots.toList()..sort();
    return slots.join(' | ');
  }

  @override
  Widget build(BuildContext context) {
    final totalHours = _calculateTotalHours();
    final totalPrice = _calculateTotalPrice();
    final userDocAsync = ref.watch(currentUserDocProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt lịch ngay trực quan'),
        backgroundColor: const Color(0xFF1B7A6B),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Container(
          color: const Color(0xFF1B7A6B),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Court Information Section
                _buildSectionTitle('Thông tin sân'),
                const SizedBox(height: 12),
                _buildInfoItem(
                  icon: Icons.sports_tennis,
                  title: 'Tên CLB',
                  content: widget.court.name,
                ),
                _buildInfoItem(
                  icon: Icons.location_on,
                  title: 'Địa chỉ',
                  content: widget.court.location,
                ),
                const SizedBox(height: 24),

                // Booking Details Section
                _buildSectionTitle('Thông tin lịch đặt'),
                const SizedBox(height: 12),
                _buildInfoItem(
                  icon: Icons.calendar_today,
                  title: 'Ngày',
                  content: DateFormat('dd/MM/yyyy').format(widget.selectedDate),
                ),
                _buildInfoItem(
                  icon: Icons.access_time,
                  title: 'Khung giờ',
                  content: _formatSelectedSlots(),
                ),
                _buildInfoItem(
                  icon: Icons.person,
                  title: 'Đối tượng',
                  content: _getCustomerTypeLabel(),
                ),
                _buildInfoItem(
                  icon: Icons.schedule,
                  title: 'Tổng giờ',
                  content: '${totalHours}h00',
                ),
                _buildPriceItem(totalPrice),
                const SizedBox(height: 24),

                // Customer Information Section
                _buildSectionTitle('Thông tin khách hàng'),
                const SizedBox(height: 12),
                userDocAsync.when(
                  data: (userDoc) {
                    final name = userDoc?['name'] ?? 'Chưa cập nhật';
                    final phone = userDoc?['phoneNumber'] ?? 'Chưa cập nhật';
                    
                    return Column(
                      children: [
                        _buildInfoItem(
                          icon: Icons.person,
                          title: 'Tên của bạn',
                          content: name,
                        ),
                        _buildInfoItem(
                          icon: Icons.phone,
                          title: 'Số điện thoại',
                          content: phone,
                        ),
                      ],
                    );
                  },
                  loading: () => Column(
                    children: [
                      _buildInfoItem(
                        icon: Icons.person,
                        title: 'Tên của bạn',
                        content: 'Đang tải...',
                      ),
                      _buildInfoItem(
                        icon: Icons.phone,
                        title: 'Số điện thoại',
                        content: 'Đang tải...',
                      ),
                    ],
                  ),
                  error: (_, __) => Column(
                    children: [
                      _buildInfoItem(
                        icon: Icons.person,
                        title: 'Tên của bạn',
                        content: 'Lỗi tải dữ liệu',
                      ),
                      _buildInfoItem(
                        icon: Icons.phone,
                        title: 'Số điện thoại',
                        content: 'Lỗi tải dữ liệu',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Confirm Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      // Generate order ID
                      final orderId =
                          '#${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
                      final totalPrice = _calculateTotalPrice();

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentScreen(
                            court: widget.court,
                            selectedDate: widget.selectedDate,
                            selectedSlots: widget.selectedSlots,
                            bookingType: widget.bookingType,
                            customerType: widget.customerType,
                            user: widget.user,
                            orderId: orderId,
                            totalPrice: totalPrice,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4A820),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      'XÁC NHẬN & THANH TOÁN',
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
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceItem(int totalPrice) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.money, color: Colors.white, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tổng tiền',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '${totalPrice.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')} đ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType inputType = TextInputType.text,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: inputType,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  String _getCustomerTypeLabel() {
    switch (widget.customerType) {
      case CustomerType.student:
        return 'Học sinh - sinh viên';
      case CustomerType.adult:
        return 'Người lớn';
      case CustomerType.group:
        return 'Nhóm';
    }
  }
}
