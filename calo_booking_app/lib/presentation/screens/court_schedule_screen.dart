// CourtScheduleScreen
// Purpose: Display court schedule for booking
//
// Inputs:
// - CourtModel court
// - BookingType bookingType
// - CustomerType customerType
//
// UI:
// - AppBar with title "Đặt lịch ngay trực quan"
// - Date picker button
// - Legend: Trống / Đã đặt / Khóa
// - Time slot grid (rows = courts A,B,C,D; columns = time slots)
// - Selectable available slots
// - Bottom button "TIẾP THEO"

import 'package:calo_booking_app/data/models/court_model.dart';
import 'package:calo_booking_app/presentation/screens/booking_confirmation_screen.dart';
import 'package:calo_booking_app/presentation/widgets/court_schedule_grid.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:calo_booking_app/presentation/widgets/booking_type_sheet.dart';
import 'package:calo_booking_app/presentation/widgets/booking_target_sheet.dart';

class CourtScheduleScreen extends StatefulWidget {
  final CourtModel court;
  final BookingType bookingType;
  final CustomerType customerType;

  const CourtScheduleScreen({
    super.key,
    required this.court,
    required this.bookingType,
    required this.customerType,
  });

  @override
  State<CourtScheduleScreen> createState() => _CourtScheduleScreenState();
}

class _CourtScheduleScreenState extends State<CourtScheduleScreen> {
  DateTime _selectedDate = DateTime.now();
  final Set<String> _selectedSlots = {}; // Format: "timeSlot-courtNumber"

  List<String> _generateTimeSlots() {
    final List<String> timeSlots = [];
    for (int hour = 6; hour < 22; hour++) {
      timeSlots.add('${hour.toString().padLeft(2, '0')}:00');
      timeSlots.add('${hour.toString().padLeft(2, '0')}:30');
    }
    return timeSlots;
  }

  List<String> _generateCourtNumbers() {
    return ['A', 'B', 'C', 'D'];
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt lịch ngay trực quan'),
        backgroundColor: const Color(0xFF1B7A6B),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Text(
                    DateFormat('dd/MM/yyyy').format(_selectedDate),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF1B7A6B),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  LegendItem(color: Colors.white, label: 'Trống'),
                  const SizedBox(width: 16),
                  LegendItem(color: Colors.red.shade700, label: 'Đã đặt'),
                  const SizedBox(width: 16),
                  LegendItem(color: Colors.grey.shade400, label: 'Khóa'),
                  const SizedBox(width: 16),
                  LegendItem(color: Colors.purple.shade400, label: 'Sự kiện'),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildScheduleGrid(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _selectedSlots.isEmpty
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingConfirmationScreen(
                              court: widget.court,
                              selectedDate: _selectedDate,
                              selectedSlots: _selectedSlots,
                              bookingType: widget.bookingType,
                              customerType: widget.customerType, user: null,
                            ),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4A820),
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  'TIẾP THEO',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget LegendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.white24, width: 0.5),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  Widget _buildScheduleGrid() {
    final timeSlots = _generateTimeSlots();
    final courtNumbers = _generateCourtNumbers();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Table(
          defaultColumnWidth: const FixedColumnWidth(80),
          border: TableBorder.all(color: Colors.grey.shade300, width: 1),
          children: [
            // Header row with court numbers
            TableRow(
              decoration: BoxDecoration(color: const Color(0xFF1B7A6B)),
              children: [
                _buildHeaderCell('Giờ'),
                ...courtNumbers.map((court) => _buildHeaderCell(court)),
              ],
            ),
            // Time slot rows
            ...timeSlots.map((timeSlot) {
              return TableRow(
                children: [
                  _buildTimeCell(timeSlot),
                  ...courtNumbers.map((court) {
                    final slotId = '$timeSlot-$court';
                    final isSelected = _selectedSlots.contains(slotId);
                    return _buildSelectableSlotCell(slotId, isSelected);
                  }),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFF1B7A6B),
      width: 80,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTimeCell(String time) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFFF5F5F5),
      width: 80,
      height: 50,
      child: Text(
        time,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 11,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildSelectableSlotCell(String slotId, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedSlots.remove(slotId);
          } else {
            _selectedSlots.add(slotId);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        height: 50,
        width: 80,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, width: 1),
          color: isSelected ? Colors.blue.shade400 : Colors.white,
        ),
        child: Center(
          child: Text(
            isSelected ? '✓' : '',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
