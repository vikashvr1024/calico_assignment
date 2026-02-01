import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService instance = ConnectivityService._internal();
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  bool _isConnected = true;

  ConnectivityService._internal() {
    _initConnectivity();
    _connectivity.onConnectivityChanged.listen(
      (result) => _updateConnectionStatus(result),
    );
  }

  Stream<bool> get connectionStatus => _connectionStatusController.stream;
  bool get isConnected => _isConnected;

  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      print('Error checking connectivity: $e');
      _isConnected = false;
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    _isConnected = result != ConnectivityResult.none;
    _connectionStatusController.add(_isConnected);

    print('Connection status changed: ${_isConnected ? "Online" : "Offline"}');
  }

  Future<bool> checkConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      print('Error checking connection: $e');
      return false;
    }
  }

  void dispose() {
    _connectionStatusController.close();
  }
}
