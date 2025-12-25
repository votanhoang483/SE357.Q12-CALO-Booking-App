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

enum BookingType {
  dateBooking,
  eventBooking,
}

class BookingTypeSheet extends StatelessWidget {
  const BookingTypeSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chọn hình thức đặt',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          BookingTypeCard(
            title: 'Đặt lịch ngày trực quan',
            description: 'Chọn ngày và giờ cụ thể để đặt sân.',
            icon: Icons.date_range,
            onTap: () {
              Navigator.pop(context, BookingType.dateBooking);
            },
          ),
          const SizedBox(height: 12),
          BookingTypeCard(
            title: 'Đặt lịch sự kiện',
            description: 'Tạo sự kiện và mời bạn bè cùng tham gia.',
            icon: Icons.event,
            onTap: () {
              Navigator.pop(context, BookingType.eventBooking);
            },
          ),
        ],
      ),
    );
  }

  Widget BookingTypeCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Colors.blue),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}