import 'package:calo_booking_app/presentation/viewmodels/auth_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to get current user document
final currentUserDocProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final authRepository = ref.watch(authRepositoryProvider);
  final userId = authRepository.currentUserId;

  if (userId == null) return null;

  return authRepository.getUserDocument(userId);
});

// Provider to get current user name
final currentUserNameProvider = FutureProvider<String?>((ref) async {
  final userDoc = await ref.watch(currentUserDocProvider.future);
  return userDoc?['name'] as String?;
});
