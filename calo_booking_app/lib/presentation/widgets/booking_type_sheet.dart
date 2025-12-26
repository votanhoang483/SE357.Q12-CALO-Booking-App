// BookingTypeSheet
// Bottom sheet for selecting booking type.
//
// UI:
// - Title: "Chọn hình thức đặt"
// - Two selectable cards:
//   1. Đặt lịch ngày trực quan
//   2. Đặt lịch sự kiện
//
// Behavior:
// - On tap, return selected BookingType via Navigator.pop

import 'package:flutter/material.dart';

enum BookingType { dateBooking, eventBooking }

class BookingTypeSheet extends StatelessWidget {
  const BookingTypeSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Chọn hình thức đặt',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B7A6B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildBookingTypeCard(
              title: 'Đặt lịch ngày trực quan',
              description:
                  'Đặt lịch ngày khi khách chơi nhiều khung giờ, nhiều sân.',
              backgroundColor: const Color(0xFFD4F1E8),
              buttonColor: const Color(0xFF1B7A6B),
              onTap: () {
                Navigator.pop(context, BookingType.dateBooking);
              },
            ),
            const SizedBox(height: 12),
            _buildBookingTypeCard(
              title: 'Đặt lịch sự kiện',
              description:
                  'Sự kiện chung bạn chơi chung với những người có cùng nâm đầm má, trình độ. Hãy những giải đấu màng tính cạnh tranh cao, nâng cao trình độ đó chủ sân tối đa lợi tức.',
              backgroundColor: const Color(0xFFF3E5F5),
              buttonColor: const Color(0xFF9C27B0),
              onTap: () {
                Navigator.pop(context, BookingType.eventBooking);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingTypeCard({
    required String title,
    required String description,
    required Color backgroundColor,
    required Color buttonColor,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: buttonColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
