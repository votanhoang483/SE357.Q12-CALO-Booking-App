import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calo_booking_app/presentation/screens/booked_schedule_screen.dart';
import 'package:calo_booking_app/presentation/screens/edit_profile_screen.dart';
import 'package:calo_booking_app/presentation/screens/login_screen.dart';
import 'package:calo_booking_app/presentation/viewmodels/auth_viewmodel.dart';
import 'package:calo_booking_app/presentation/viewmodels/user_viewmodel.dart';

class AccountScreen extends ConsumerStatefulWidget {
  final Function(int) onNavChange;

  const AccountScreen({super.key, required this.onNavChange});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  @override
  Widget build(BuildContext context) {
    final userDocAsync = ref.watch(currentUserDocProvider);
    final authRepository = ref.watch(authRepositoryProvider);
    final screenContext = context; // Store screen context

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          color: const Color(0xFFF0F9F7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Card
              Container(
                color: const Color(0xFFF0F9F7),
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: userDocAsync.when(
                      data: (userDoc) {
                        final name = userDoc?['name'] ?? 'Người dùng';
                        final email =
                            userDoc?['email'] ??
                            authRepository.currentUserEmail ??
                            'N/A';
                        final phone =
                            userDoc?['phoneNumber'] ?? 'Chưa cập nhật';

                        return Row(
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
                                    name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1B7A6B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$phone | $email',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => Row(
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
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Đang tải...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B7A6B),
                                  ),
                                ),
                                SizedBox(height: 4),
                                CircularProgressIndicator(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      error: (_, __) => Row(
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
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Người dùng',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B7A6B),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Không thể tải thông tin',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Activity Section
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  'Hoạt động',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1B7A6B),
                  ),
                ),
              ),
              _buildMenuCard(
                icon: Icons.calendar_today,
                title: 'Lịch đã đặt',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BookedScheduleScreen(),
                    ),
                  );
                },
              ),
              _buildMenuCard(
                icon: Icons.people,
                title: 'Nhóm của tôi',
                onTap: () {},
              ),
              _buildMenuCard(
                icon: Icons.school,
                title: 'Danh sách lịch học',
                onTap: () {},
              ),

              const SizedBox(height: 12),

              // System Section
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  'Hệ thống',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1B7A6B),
                  ),
                ),
              ),
              _buildMenuCard(
                icon: Icons.settings,
                title: 'Cài đặt',
                onTap: () {},
              ),
              _buildMenuCard(
                icon: Icons.info,
                title: 'Thông tin phiên bản',
                onTap: () {},
              ),
              _buildMenuCard(
                icon: Icons.shield,
                title: 'Điều khoản và chính sách',
                onTap: () {},
              ),

              // Edit Profile Button
              _buildMenuCard(
                icon: Icons.edit,
                title: 'Chỉnh sửa thông tin cá nhân',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () => _showLogoutDialog(screenContext),
                  child: _buildLogoutButton(),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1B7A6B),
        selectedItemColor: const Color(0xFFD4A820),
        unselectedItemColor: Colors.white70,
        currentIndex: 3,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          widget.onNavChange(index);
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(icon: const Icon(Icons.map), label: 'Bản đồ'),
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

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1B7A6B), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.login, color: Colors.red, size: 24),
          const SizedBox(width: 16),
          const Text(
            'Đăng xuất',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext screenContext) {
    showDialog(
      context: screenContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog with dialog context

              try {
                print('🔓 Logging out...');
                await ref.read(authProvider.notifier).logout();

                print('✅ Logout successful!');

                if (screenContext.mounted) {
                  ScaffoldMessenger.of(screenContext).showSnackBar(
                    const SnackBar(
                      content: Text('Đã đăng xuất thành công'),
                      duration: Duration(seconds: 1),
                    ),
                  );

                  // Navigate to LoginScreen after logout
                  await Future.delayed(const Duration(milliseconds: 500));
                  if (screenContext.mounted) {
                    Navigator.of(screenContext).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                }

                print('🔄 Navigated to LoginScreen');
              } catch (e) {
                print('❌ Logout error: $e');
                if (screenContext.mounted) {
                  ScaffoldMessenger.of(
                    screenContext,
                  ).showSnackBar(SnackBar(content: Text('Lỗi đăng xuất: $e')));
                }
              }
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
