// BookingTargetSheet
// Bottom sheet for selecting customer type.
//
// UI:
// - Title: "Chọn đối tượng áp dụng"
// - Radio options:
//   - Học sinh - sinh viên
//   - Người lớn
//
// Behavior:
// - Confirm button returns selected CustomerType

import 'package:flutter/material.dart';

enum CustomerType { student, adult, group }

class BookingTargetSheet extends StatefulWidget {
  const BookingTargetSheet({super.key});

  @override
  _BookingTargetSheetState createState() => _BookingTargetSheetState();
}

class _BookingTargetSheetState extends State<BookingTargetSheet> {
  CustomerType _selectedType = CustomerType.adult;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Chọn đối tượng áp dụng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B7A6B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Student option
            _buildRadioOption(
              title: 'Học sinh - sinh viên',
              value: CustomerType.student,
            ),
            const SizedBox(height: 12),
            // Adult option
            _buildRadioOption(title: 'Người lớn', value: CustomerType.adult),
            const SizedBox(height: 24),
            // Continue button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, _selectedType);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B7A6B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  'TIẾP TỤC',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption({
    required String title,
    required CustomerType value,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: RadioListTile<CustomerType>(
        title: Text(title, style: const TextStyle(fontSize: 14)),
        value: value,
        groupValue: _selectedType,
        activeColor: const Color(0xFF1B7A6B),
        onChanged: (newValue) {
          setState(() {
            _selectedType = newValue!;
          });
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}
