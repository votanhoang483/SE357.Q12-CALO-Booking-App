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

enum CustomerType {
  student,
  adult,
  group
}

class BookingTargetSheet extends StatefulWidget {
  const BookingTargetSheet({super.key});

  @override
  _BookingTargetSheetState createState() => _BookingTargetSheetState();
}

class _BookingTargetSheetState extends State<BookingTargetSheet> {
  CustomerType _selectedType = CustomerType.adult;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chọn đối tượng áp dụng',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          RadioListTile<CustomerType>(
            title: const Text('Học sinh - sinh viên'),
            value: CustomerType.student,
            groupValue: _selectedType,
            onChanged: (value) {
              setState(() {
                _selectedType = value!;
              });
            },
          ),
          RadioListTile<CustomerType>(
            title: const Text('Người lớn'),
            value: CustomerType.adult,
            groupValue: _selectedType,
            onChanged: (value) {
              setState(() {
                _selectedType = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, _selectedType);
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }


}