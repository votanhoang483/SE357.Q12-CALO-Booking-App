import 'dart:async';

/// Service để quản lý việc load data song song (parallel) và concurrent
///
/// Sử dụng các pattern:
/// - Future.wait() cho parallel execution
/// - Stream cho real-time updates
/// - Batch operations cho multiple writes
class ParallelDataService {
  /// Load nhiều data sources cùng lúc (parallel)
  ///
  /// Ví dụ:
  /// ```dart
  /// final results = await parallelDataService.loadMultiple([
  ///   () => bookingRepo.getUserBookings(userId),
  ///   () => courtRepo.getAllActiveCourts(),
  ///   () => userRepo.getCurrentUser(),
  /// ]);
  /// ```
  static Future<List<T>> loadMultiple<T>(
    List<Future<T> Function()> loaders,
  ) async {
    return Future.wait(loaders.map((loader) => loader()));
  }

  /// Load với timeout để tránh blocking quá lâu
  static Future<List<T?>> loadMultipleWithTimeout<T>(
    List<Future<T> Function()> loaders, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    return Future.wait(
      loaders.map((loader) async {
        try {
          return await loader().timeout(timeout);
        } catch (e) {
          print('⚠️ Loader failed or timed out: $e');
          return null;
        }
      }),
    );
  }

  /// Load data với fallback nếu một trong các request fail
  static Future<Map<String, dynamic>> loadWithFallback({
    required Map<String, Future<dynamic> Function()> loaders,
    required Map<String, dynamic> fallbacks,
  }) async {
    final results = <String, dynamic>{};

    await Future.wait(
      loaders.entries.map((entry) async {
        try {
          results[entry.key] = await entry.value();
        } catch (e) {
          print('⚠️ ${entry.key} failed, using fallback: $e');
          results[entry.key] = fallbacks[entry.key];
        }
      }),
    );

    return results;
  }

  /// Chạy các task theo batch để không overload
  ///
  /// Ví dụ: Load 100 images, nhưng chỉ 5 cái cùng lúc
  static Future<List<T>> loadInBatches<T>(
    List<Future<T> Function()> loaders, {
    int batchSize = 5,
  }) async {
    final results = <T>[];

    for (var i = 0; i < loaders.length; i += batchSize) {
      final batch = loaders.skip(i).take(batchSize).toList();
      final batchResults = await Future.wait(batch.map((l) => l()));
      results.addAll(batchResults);
    }

    return results;
  }

  /// Race - lấy kết quả đầu tiên hoàn thành
  /// Hữu ích khi có nhiều data sources, lấy cái nhanh nhất
  static Future<T> race<T>(List<Future<T> Function()> loaders) {
    return Future.any(loaders.map((loader) => loader()));
  }
}

/// Mixin để thêm parallel loading vào ViewModel
mixin ParallelLoadingMixin {
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadParallel(List<Future<void> Function()> loaders) async {
    _isLoading = true;
    _error = null;

    try {
      await Future.wait(loaders.map((l) => l()));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
    }
  }
}
