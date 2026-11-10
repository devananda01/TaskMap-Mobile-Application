import 'package:connectivity_plus/connectivity_plus.dart';

/// Wraps connectivity_plus. This only reports whether a network interface
/// (Wi-Fi/mobile) is currently up — it can't confirm the internet behind it
/// is actually reachable, which is a fine tradeoff for this app's needs.
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return _hasConnection(results);
  }

  Stream<bool> onStatusChange() {
    return _connectivity.onConnectivityChanged.map(_hasConnection);
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }
}
