// CourtScheduleScreen
// Purpose: Display court schedule for booking with timeline view
//
// Inputs:
// - CourtModel court
// - BookingType bookingType
// - CustomerType customerType
//
// UI:
// - AppBar with date picker
// - Info box with notice
// - Timeline schedule with courts (Sân 1-4)
// - Duration slider
// - Total hours and price display
// - Bottom button "TIẾP THEO"

import 'package:calo_booking_app/data/models/court_model.dart';
import 'package:calo_booking_app/presentation/screens/booking_confirmation_screen.dart';
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
  // Format: {"court": "Sân 1", "startTime": "06:00", "endTime": "06:30", "startIndex": 0}
  final Set<Map<String, dynamic>> _selectedSlots = {};
  final List<String> _courtNames = ['Sân 1', 'Sân 2', 'Sân 3', 'Sân 4'];

  // Mock data for booked slots: Map<courtName, List<bookedRanges>>
  final Map<String, List<(int, int)>> _bookedSlots = {
    'Sân 1': [(6, 8)], // 6:00-8:00
    'Sân 2': [(5, 10)], // 5:00-10:00
    'Sân 3': [],
    'Sân 4': [(8, 12)], // 8:00-12:00
  };

  List<String> _generateTimeSlots() {
    final List<String> timeSlots = [];
    for (int hour = 6; hour < 22; hour++) {
      timeSlots.add('${hour.toString().padLeft(2, '0')}:00');
      timeSlots.add('${hour.toString().padLeft(2, '0')}:30');
    }
    return timeSlots;
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

  int _getTotalMinutes() {
    return _selectedSlots.length * 30;
  }

  int _getTotalPrice() {
    final hours = _getTotalMinutes() / 60;
    return (widget.court.pricePerHour * hours).toInt();
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.white24, width: 0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeSlots = _generateTimeSlots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt lịch ngay trực quan'),
        backgroundColor: const Color(0xFF1B7A6B),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Date picker section
          Container(
            color: const Color(0xFF1B7A6B),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Xem sân & bảng giá',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
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
          ),

          // Legend section
          Container(
            width: double.infinity,
            color: const Color(0xFF1B7A6B),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildLegendItem(Colors.white, 'Trống'),
                  const SizedBox(width: 16),
                  _buildLegendItem(Colors.red.shade400, 'Đã đặt'),
                  const SizedBox(width: 16),
                  _buildLegendItem(Colors.grey.shade400, 'Khóa'),
                  const SizedBox(width: 16),
                  _buildLegendItem(Colors.green.shade300, 'Được chọn'),
                ],
              ),
            ),
          ),

          // Info box
          Container(
            margin: const EdgeInsets.all(12.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border.all(color: Colors.blue.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Lưu ý: Nếu bạn cần đặt lịch có định vui lòng liên hệ: 0964.784.579 và 0332.858.359 để được hỗ trợ',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade900,
                height: 1.5,
              ),
            ),
          ),

          // Timeline schedule with fixed left column
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: _buildFixedColumnTimelineSchedule(timeSlots),
            ),
          ),

          // Summary section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1B7A6B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Slot details
                if (_selectedSlots.isNotEmpty)
                  
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tổng giờ: ${_getTotalMinutes() ~/ 60}h ${_getTotalMinutes() % 60}m',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Tổng tiền: ${_getTotalPrice().toStringAsFixed(0)} đ',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // TIẾP THEO button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _selectedSlots.isEmpty
                    ? null
                    : () {
                        // Convert selected slots to list with details
                        final List<Map<String, dynamic>> slotDetails =
                            _selectedSlots.toList();

                        // Convert to Set<String> for compatibility
                        final Set<String> slotIds = _selectedSlots
                            .map(
                              (slot) =>
                                  '${slot['court']}-${slot['startIndex']}',
                            )
                            .toSet();

                        // Print details for debugging
                        print('📅 Selected Slots Details:');
                        for (var slot in _selectedSlots) {
                          print(
                            '  - ${slot['court']}: ${slot['startTime']} - ${slot['endTime']}',
                          );
                        }
                        print(
                          '📊 Total: ${_getTotalMinutes()} minutes, ${_getTotalPrice()} đ',
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingConfirmationScreen(
                              court: widget.court,
                              selectedDate: _selectedDate,
                              selectedSlots: slotIds,
                              bookingType: widget.bookingType,
                              customerType: widget.customerType,
                              user: null,
                              slotDetails: slotDetails, // Pass detailed slots
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

  Widget _buildFixedColumnTimelineSchedule(List<String> timeSlots) {
    return Row(
      children: [
        // Fixed left column (court names)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              width: 60,
              height: 40,
              child: Center(
                child: Text(
                  'Giờ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            ..._courtNames.map((court) {
              return SizedBox(
                width: 60,
                height: 60,
                child: Center(
                  child: Text(
                    court,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }),
          ],
        ),
        // Scrollable right section (time slots)
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time header
                Row(
                  children: [
                    ...timeSlots.map((time) {
                      return SizedBox(
                        width: 50,
                        height: 40,
                        child: Text(
                          time,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }),
                  ],
                ),
                // Court rows
                ..._courtNames.map((court) {
                  final bookedRanges = _bookedSlots[court] ?? [];
                  return Row(
                    children: [
                      ...List.generate(timeSlots.length, (index) {
                        final slotKey = '$court-$index';
                        final isBooked = bookedRanges.any(
                          (range) => index >= range.$1 && index < range.$2,
                        );
                        final isSelected = _selectedSlots.any(
                          (slot) =>
                              slot['court'] == court &&
                              slot['startIndex'] == index,
                        );

                        // Calculate start and end time
                        final startHour = 6 + (index ~/ 2);
                        final startMin = (index % 2) * 30;
                        final endHour = 6 + ((index + 1) ~/ 2);
                        final endMin = ((index + 1) % 2) * 30;

                        final startTime =
                            '${startHour.toString().padLeft(2, '0')}:${startMin.toString().padLeft(2, '0')}';
                        final endTime =
                            '${endHour.toString().padLeft(2, '0')}:${endMin.toString().padLeft(2, '0')}';

                        return GestureDetector(
                          onTap: isBooked
                              ? null
                              : () {
                                  setState(() {
                                    final slotData = {
                                      'court': court,
                                      'startIndex': index,
                                      'startTime': startTime,
                                      'endTime': endTime,
                                    };

                                    // Kiểm tra nếu slot này đã được chọn
                                    final existing = _selectedSlots.firstWhere(
                                      (slot) =>
                                          slot['court'] == court &&
                                          slot['startIndex'] == index,
                                      orElse: () => {},
                                    );

                                    if (existing.isNotEmpty) {
                                      _selectedSlots.remove(existing);
                                    } else {
                                      _selectedSlots.add(slotData);
                                    }
                                  });
                                },
                          child: Container(
                            width: 50,
                            height: 60,
                            margin: const EdgeInsets.only(right: 2),
                            decoration: BoxDecoration(
                              color: isBooked
                                  ? Colors.red.shade400
                                  : isSelected
                                  ? Colors.green.shade300
                                  : Colors.white,
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: isSelected
                                ? const Center(
                                    child: Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  )
                                : null,
                          ),
                        );
                      }),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
