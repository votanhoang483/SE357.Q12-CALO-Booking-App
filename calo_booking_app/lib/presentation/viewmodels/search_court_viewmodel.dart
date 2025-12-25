import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calo_booking_app/data/models/court_model.dart';
import 'package:calo_booking_app/data/repositories/court_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/legacy.dart';

// Provider for CourtRepository
final courtRepositoryProvider = Provider((ref) {
  return CourtRepository(FirebaseFirestore.instance);
});

// StateNotifier for SearchCourtViewModel
class SearchCourtViewModel extends StateNotifier<AsyncValue<List<CourtModel>>> {
  final CourtRepository _courtRepository;

  String _keyword = '';

  void updateKeyword(String value) {
    _keyword = value.toLowerCase();
    loadActiveCourts();
  }

  SearchCourtViewModel(this._courtRepository)
    : super(const AsyncValue.loading()) {
    loadActiveCourts();
  }

  Future<void> loadActiveCourts() async {
    try {
      final courts = await _courtRepository.getAllActiveCourts();
      final filtered = courts.where((c) {
        return c.name.toLowerCase().contains(_keyword) ||
            c.location.toLowerCase().contains(_keyword);
      }).toList();

      state = AsyncValue.data(filtered);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Riverpod provider for SearchCourtViewModel
final searchCourtViewModelProvider =
    StateNotifierProvider<SearchCourtViewModel, AsyncValue<List<CourtModel>>>((
      ref,
    ) {
      final courtRepository = ref.watch(courtRepositoryProvider);
      return SearchCourtViewModel(courtRepository);
    });

// Separate provider to load courts on initialization
