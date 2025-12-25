import 'package:calo_booking_app/data/models/court_model.dart';
import 'package:calo_booking_app/presentation/screens/court_detail_screen.dart';
import 'package:calo_booking_app/presentation/screens/account_screen.dart';
import 'package:calo_booking_app/presentation/screens/map_screen.dart';
import 'package:calo_booking_app/presentation/screens/notification_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('vi_VN');
  }

  // Mock data - Replace with real data from repository
  final List<CourtModel> courts = [
    CourtModel(
      id: '1',
      name: 'Câu lạc bộ cầu lông cây da 1',
      location: '(32m) Hẻm 05 Đinh Tấn Quỳ, Dương ...',
      pricePerHour: 50000,
      isActive: true,
    ),
    CourtModel(
      id: '2',
      name: 'Câu lạc bộ cầu lông cây da 1',
      location: '(32m) Hẻm 05 Đinh Tấn Quỳ, Dương ...',
      pricePerHour: 50000,
      isActive: true,
    ),
    CourtModel(
      id: '3',
      name: 'Câu lạc bộ cầu lông cây da 1',
      location: '(32m) Hẻm 05 Đinh Tấn Quỳ, Dương ...',
      pricePerHour: 50000,
      isActive: true,
    ),
  ];

  String _getUserName() {
    return 'Võ Tân Hoàng';
  }

  String _getCurrentDateTime() {
    return DateFormat('EEEE, dd/MM/yyyy', 'vi_VN')
        .format(DateTime.now())
        .replaceFirstMapped(
          RegExp(r'^.'),
          (match) => match.group(0)!.toUpperCase(),
        );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show different screens based on selected nav index
    switch (_selectedNavIndex) {
      case 1:
        return MapScreen(
          onNavChange: (index) {
            setState(() {
              _selectedNavIndex = index;
            });
          },
        );
      case 2:
        return NotificationScreen(
          onNavChange: (index) {
            setState(() {
              _selectedNavIndex = index;
            });
          },
        );
      case 3:
        return AccountScreen(
          onNavChange: (index) {
            setState(() {
              _selectedNavIndex = index;
            });
          },
        );
      default:
        // Home screen
        return Scaffold(
          body: Column(
            children: [
              // Header Section
              Container(
                color: const Color(0xFF1B7A6B),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: MediaQuery.of(context).padding.top),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey.shade300,
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getCurrentDateTime(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getUserName(),
                                style: const TextStyle(
                                  color: Color(0xFFD4A820),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Search Bar
              Container(
                color: const Color(0xFF1B7A6B),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEDCC),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm',
                            hintStyle: TextStyle(color: Colors.grey.shade600),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEDCC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.search, color: Colors.grey.shade700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEDCC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: () {},
                        icon: Icon(
                          Icons.favorite_border,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Court Cards List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: courts.length,
                  itemBuilder: (context, index) {
                    final court = courts[index];
                    return buildCourtCard(context, court);
                  },
                ),
              ),
            ],
          ),
          // Bottom Navigation Bar
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: const Color(0xFF1B7A6B),
            selectedItemColor: const Color(0xFFD4A820),
            unselectedItemColor: Colors.white70,
            currentIndex: _selectedNavIndex,
            type: BottomNavigationBarType.fixed,
            onTap: (index) {
              setState(() {
                _selectedNavIndex = index;
              });
            },
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home),
                label: 'Trang chủ',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.map),
                label: 'Bản đồ',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.notifications),
                label: 'Nội bật',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person),
                label: 'Tài khoản',
              ),
            ],
          ),
        );
    }
  }

  Widget buildCourtCard(BuildContext context, CourtModel court) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Court Image
          Stack(
            children: [
              Container(
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  color: Colors.grey.shade300,
                ),
                child: const Center(
                  child: Icon(Icons.image, size: 40, color: Colors.grey),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.favorite_border, size: 20),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.location_on, size: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Court Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B7A6B),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.sports_tennis,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            court.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            court.location,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      '06:00 - 22:00',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CourtDetailScreen(court: court),
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
                      'ĐẶT LỊCH',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
