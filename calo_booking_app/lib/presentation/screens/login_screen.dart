import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calo_booking_app/presentation/viewmodels/auth_viewmodel.dart';
import 'package:calo_booking_app/presentation/viewmodels/user_viewmodel.dart';
import 'package:calo_booking_app/presentation/screens/register_screen.dart';
import 'package:calo_booking_app/presentation/screens/home_screen.dart';
import 'package:calo_booking_app/presentation/screens/staff_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập email và mật khẩu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('🔐 Attempting login with email: ${_emailController.text.trim()}');
      await ref
          .read(authProvider.notifier)
          .login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      print('✅ Login successful!');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đăng nhập thành công')));

        // Wait a moment for user data to load
        await Future.delayed(const Duration(milliseconds: 500));

        // Get user role to determine which screen to show
        final userDoc = await ref.read(currentUserDocProvider.future);
        final role = userDoc?['role'] as String? ?? 'user';

        if (mounted) {
          // Navigate based on role
          if (role == 'staff') {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const StaffScreen()),
              (route) => false,
            );
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          }
        }

        print('🔄 Navigated to appropriate screen based on role: $role');
      }
    } catch (e) {
      print('❌ Login error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Đăng nhập thất bại: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Logo/Title
                const Center(
                  child: Text(
                    'CALO',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF016D3B),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Ứng dụng đặt sân cầu lông',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 60),

                // Email Field
                const Text(
                  'Email',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Nhập email của bạn',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Password Field
                const Text(
                  'Mật khẩu',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Nhập mật khẩu',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: Implement forgot password
                    },
                    child: const Text(
                      'Quên mật khẩu?',
                      style: TextStyle(color: Color(0xFF016D3B), fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF016D3B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Đăng nhập',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    Expanded(
                      child: Container(height: 1, color: Colors.grey.shade300),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Hoặc',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(height: 1, color: Colors.grey.shade300),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Register Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFF016D3B),
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Đăng ký',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF016D3B),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
