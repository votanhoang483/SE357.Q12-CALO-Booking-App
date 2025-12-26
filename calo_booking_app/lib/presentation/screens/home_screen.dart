import 'package:calo_booking_app/data/models/court_model.dart';
import 'package:calo_booking_app/presentation/screens/court_detail_screen.dart';
import 'package:calo_booking_app/presentation/screens/account_screen.dart';
import 'package:calo_booking_app/presentation/screens/court_schedule_screen.dart';
import 'package:calo_booking_app/presentation/screens/map_screen.dart';
import 'package:calo_booking_app/presentation/screens/notification_screen.dart';
import 'package:calo_booking_app/presentation/viewmodels/search_court_viewmodel.dart';
import 'package:calo_booking_app/presentation/viewmodels/bookings_viewmodel.dart';
import 'package:calo_booking_app/presentation/viewmodels/user_viewmodel.dart';
import 'package:calo_booking_app/presentation/widgets/booking_target_sheet.dart';
import 'package:calo_booking_app/presentation/widgets/booking_type_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('vi_VN');
    // Load bookings from Firestore on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingsProvider.notifier).loadAllBookings();
    });
  }

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

  String _getCourtImageUrl(String courtName) {
    // Map court names to image URLs
    if (courtName.contains('CALO')) {
      return 'https://images.unsplash.com/photo-1721760886982-3c643f05813d?q=80&w=1470&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D';
    } else if (courtName.contains('Phoenix')) {
      return 'https://images.unsplash.com/photo-1617696618050-b0fef0c666af?q=80&w=1740&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D';
    }
    return 'https://images.unsplash.com/photo-1554284147-8e4ec759661f?w=500&h=300&fit=crop';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCourtBottomSheet(BuildContext context, CourtModel court) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Court Image - Full Width
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: Image.network(
                    _getCourtImageUrl(court.name),
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(Icons.image, size: 40, color: Colors.grey),
                      );
                    },
                  ),
                ),
              ),
              // Close button
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Chi tiết sân',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              // Court Info
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rating
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                '4.3',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(12 đánh giá)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Court name
                    Text(
                      court.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Location
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 20,
                          color: const Color(0xFF016D3B),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            court.location,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Operating hours
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 20,
                          color: const Color(0xFF016D3B),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '06:00 - 22:00',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Phone
                    Row(
                      children: [
                        const Icon(
                          Icons.phone,
                          size: 20,
                          color: const Color(0xFF016D3B),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Liên hệ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Booking button
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close bottom sheet
                          // Delay the dialog to ensure context is still valid
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (mounted) {
                              _showBookingTypeDialog(context, court);
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4A820),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'ĐẶT LỊCH',
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showBookingTypeDialog(
    BuildContext context,
    CourtModel court,
  ) async {
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
  }

  @override
  Widget build(BuildContext context) {
    // Watch courts from Riverpod provider
    final courtsState = ref.watch(searchCourtViewModelProvider);
    final userNameAsync = ref.watch(currentUserNameProvider);

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
                color: const Color(0xFF016D3B),
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
                              userNameAsync.when(
                                data: (name) => Text(
                                  name ?? 'Xin chào',
                                  style: const TextStyle(
                                    color: Color(0xFFD4A820),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                loading: () => const Text(
                                  'Đang tải...',
                                  style: TextStyle(
                                    color: Color(0xFFD4A820),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                error: (_, __) => const Text(
                                  'Xin chào',
                                  style: TextStyle(
                                    color: Color(0xFFD4A820),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                color: const Color(0xFF016D3B),
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
                          onChanged: (value) {
                            ref
                                .read(searchCourtViewModelProvider.notifier)
                                .updateKeyword(value);
                          },
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
                child: courtsState.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Lỗi tải dữ liệu',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  data: (courts) {
                    if (courts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.sports_tennis,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Không tìm thấy sân',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: courts.length,
                      itemBuilder: (context, index) {
                        final court = courts[index];
                        return GestureDetector(
                          onTap: () => _showCourtBottomSheet(context, court),
                          child: buildCourtCard(context, court),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          // Bottom Navigation Bar
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: const Color(0xFF016D3B),
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
                label: 'Nổi bật',
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Court Image - Full Width
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: Image.network(
                    _getCourtImageUrl(court.name),
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(Icons.image, size: 40, color: Colors.grey),
                      );
                    },
                  ),
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
                        color: const Color(0xFF016D3B),
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
                      _showBookingTypeDialog(context, court);
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
