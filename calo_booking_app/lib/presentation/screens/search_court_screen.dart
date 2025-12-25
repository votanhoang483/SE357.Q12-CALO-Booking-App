import 'package:calo_booking_app/presentation/screens/court_detail_screen.dart';
import 'package:calo_booking_app/presentation/viewmodels/search_court_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchCourtScreen extends ConsumerWidget {
  const SearchCourtScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchCourtViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Search Court')),
      body: Column(
        children: [
          // 🔍 SEARCH BAR — THÊM Ở ĐÂY
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search court',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                ref
                    .read(searchCourtViewModelProvider.notifier)
                    .updateKeyword(value);
              },
            ),
          ),

          // 📋 COURT LIST
          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
              data: (courts) {
                if (courts.isEmpty) {
                  return const Center(child: Text('No courts found'));
                }

                return ListView.builder(
                  itemCount: courts.length,
                  itemBuilder: (context, index) {
                    final court = courts[index];
                    return ListTile(
                      title: Text(court.name),
                      subtitle: Text(court.location),
                      trailing: Text('${court.pricePerHour} / h'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CourtDetailScreen(court: court),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
