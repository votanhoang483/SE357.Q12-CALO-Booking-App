import 'package:calo_booking_app/presentation/screens/home_screen.dart';
import 'package:calo_booking_app/presentation/screens/staff_screen.dart';
import 'package:calo_booking_app/presentation/screens/login_screen.dart';
import 'package:calo_booking_app/presentation/viewmodels/auth_viewmodel.dart';
import 'package:calo_booking_app/presentation/viewmodels/user_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch auth state
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CALO Booking App',
      home: authState.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (error, stackTrace) =>
            const Scaffold(body: Center(child: Text('Lỗi tải dữ liệu'))),
        data: (user) {
          if (user == null) {
            return const LoginScreen();
          }

          // User is logged in, check role
          return _RoleBasedHome(userId: user.uid);
        },
      ),
    );
  }
}

class _RoleBasedHome extends ConsumerWidget {
  final String userId;

  const _RoleBasedHome({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDocAsync = ref.watch(currentUserDocProvider);

    return userDocAsync.when(
      data: (userDoc) {
        final role = userDoc?['role'] as String? ?? 'user';

        // Navigate based on role
        if (role == 'staff') {
          return const StaffScreen();
        } else {
          return const HomeScreen();
        }
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => const Scaffold(
        body: Center(child: Text('Lỗi tải thông tin người dùng')),
      ),
    );
  }
}
