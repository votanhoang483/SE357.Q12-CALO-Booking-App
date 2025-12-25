import 'package:calo_booking_app/data/models/court_model.dart';
import 'package:flutter/material.dart';

class CourtScheduleGrid extends StatelessWidget {
  final CourtModel court;
  final DateTime date;
  final int numberOfCourts;

  const CourtScheduleGrid({
    super.key,
    required this.court,
    required this.date,
    this.numberOfCourts = 4,
  });

  List<String> _generateTimeSlots() {
    final List<String> timeSlots = [];
    for (int hour = 6; hour < 22; hour++) {
      timeSlots.add('${hour.toString().padLeft(2, '0')}:00');
      timeSlots.add('${hour.toString().padLeft(2, '0')}:30');
    }
    return timeSlots;
  }

  List<String> _generateCourtNumbers() {
    return List.generate(numberOfCourts, (index) => 'Sân ${index + 1}');
  }

  @override
  Widget build(BuildContext context) {
    final timeSlots = _generateTimeSlots();
    final courtNumbers = _generateCourtNumbers();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Table(
          border: TableBorder.all(color: Colors.grey.shade300, width: 1),
          children: [
            // Header row with court numbers
            TableRow(
              decoration: BoxDecoration(color: Colors.blue.shade50),
              children: [
                _buildHeaderCell('Thời gian'),
                ...courtNumbers.map((court) => _buildHeaderCell(court)),
              ],
            ),
            // Time slot rows
            ...timeSlots.map((timeSlot) {
              return TableRow(
                children: [
                  _buildTimeCell(timeSlot),
                  ...courtNumbers.map((court) => _buildSlotCell()),
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
      color: Colors.blue.shade100,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildTimeCell(String time) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey.shade100,
      width: 80,
      child: Text(
        time,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
      ),
    );
  }

  Widget _buildSlotCell() {
    return GestureDetector(
      onTap: () {
        // Xử lý sự kiện khi nhấn vào slot
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        height: 50,
        width: 80,
        color: Colors.green.shade100,
        child: const Center(
          child: Text(
            'Có',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
