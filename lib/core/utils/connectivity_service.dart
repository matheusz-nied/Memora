import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectivityService {
  ConnectivityService([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Stream<bool> get onlineChanges {
    return _connectivity.onConnectivityChanged.map(_isOnlineResult).distinct();
  }

  Future<bool> isOnline() async {
    return _isOnlineResult(await _connectivity.checkConnectivity());
  }

  bool _isOnlineResult(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final onlineStatusProvider = StreamProvider<bool>((ref) {
  return ref.watch(connectivityServiceProvider).onlineChanges;
});
