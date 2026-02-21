import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/mole_service.dart';

/// Global MoleService instance.
final moleServiceProvider = Provider<MoleService>((ref) => MoleService());

/// Current navigation index.
final selectedNavIndexProvider = StateProvider<int>((ref) => 0);

/// Mole version string.
final moleVersionProvider = FutureProvider<String>((ref) async {
  final service = ref.read(moleServiceProvider);
  try {
    return await service.version();
  } catch (_) {
    return 'Not installed';
  }
});

/// Whether mo binary is available.
final moleAvailableProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(moleServiceProvider);
  return service.isAvailable();
});

/// Live system status — auto-refreshes every 2 seconds.
class SystemStatusNotifier
    extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final MoleService _service;
  Timer? _timer;

  SystemStatusNotifier(this._service) : super(const AsyncValue.loading()) {
    _fetch();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _fetch());
  }

  Future<void> _fetch() async {
    try {
      final data = await _service.getSystemStatus();
      if (mounted) state = AsyncValue.data(data);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final systemStatusProvider =
    StateNotifierProvider<
      SystemStatusNotifier,
      AsyncValue<Map<String, dynamic>>
    >((ref) => SystemStatusNotifier(ref.read(moleServiceProvider)));

/// Clean dry-run results.
final cleanDryRunProvider = FutureProvider.autoDispose<String>((ref) async {
  final service = ref.read(moleServiceProvider);
  return service.cleanDryRunStream().join('\n');
});

/// Optimize dry-run results.
final optimizeDryRunProvider = FutureProvider.autoDispose<String>((ref) async {
  final service = ref.read(moleServiceProvider);
  return service.optimizeDryRun();
});
