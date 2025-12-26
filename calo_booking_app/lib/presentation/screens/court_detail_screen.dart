
import 'package:calo_booking_app/data/models/court_model.dart';
import 'package:calo_booking_app/presentation/screens/court_schedule_screen.dart';
import 'package:calo_booking_app/presentation/widgets/booking_target_sheet.dart';
import 'package:calo_booking_app/presentation/widgets/booking_type_sheet.dart';
import 'package:flutter/material.dart';

class CourtDetailScreen extends StatelessWidget {
  final CourtModel court;

  const CourtDetailScreen({super.key, required this.court});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(court.name)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                court.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('Location: ${court.location}'),
              const SizedBox(height: 8),
              Text('Price per hour: \$${court.pricePerHour}'),
              const SizedBox(height: 8),
              Text('Status: ${court.isActive ? "Active" : "Inactive"}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final bookingType = await showDialog<BookingType>(
                    context: context,
                    builder: (_) => const BookingTypeSheet(),
                  );

                  if (bookingType == null) return;

                  final customerType = await showDialog<CustomerType>(
                    context: context,
                    builder: (_) => const BookingTargetSheet(),
                  );

                  if (customerType == null) return;

                  // Navigate to schedule screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CourtScheduleScreen(
                        court: court,
                        bookingType: bookingType,
                        customerType: customerType,
                      ),
                    ),
                  );
                },

                child: const Text('Đặt lịch'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
