import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

enum ConnectionStatus {
  online,
  offline,
  unknown,
}

enum ConnectionType {
  wifi,
  mobile,
  ethernet,
  none,
}

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<ConnectionStatus> _statusController =
      StreamController<ConnectionStatus>.broadcast();

  ConnectionStatus _currentStatus = ConnectionStatus.unknown;
  ConnectionType _currentType = ConnectionType.none;

  Stream<ConnectionStatus> get statusStream => _statusController.stream;
  ConnectionStatus get currentStatus => _currentStatus;
  ConnectionType get currentType => _currentType;

  bool get isOnline => _currentStatus == ConnectionStatus.online;
  bool get isOffline => _currentStatus == ConnectionStatus.offline;

  Future<void> initialize() async {
    // Check initial connectivity
    await _updateConnectionStatus();

    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      _updateConnectionStatus();
    });
  }

  Future<void> _updateConnectionStatus() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateStatus(result);
    } catch (e) {
      _currentStatus = ConnectionStatus.unknown;
      _currentType = ConnectionType.none;
      _statusController.add(_currentStatus);
    }
  }

  void _updateStatus(ConnectivityResult result) {
    ConnectionStatus newStatus;
    ConnectionType newType;

    switch (result) {
      case ConnectivityResult.wifi:
        newStatus = ConnectionStatus.online;
        newType = ConnectionType.wifi;
        break;
      case ConnectivityResult.mobile:
        newStatus = ConnectionStatus.online;
        newType = ConnectionType.mobile;
        break;
      case ConnectivityResult.ethernet:
        newStatus = ConnectionStatus.online;
        newType = ConnectionType.ethernet;
        break;
      case ConnectivityResult.none:
        newStatus = ConnectionStatus.offline;
        newType = ConnectionType.none;
        break;
      default:
        newStatus = ConnectionStatus.unknown;
        newType = ConnectionType.none;
    }

    if (newStatus != _currentStatus) {
      _currentStatus = newStatus;
      _currentType = newType;
      _statusController.add(_currentStatus);
    } else {
      _currentType = newType;
    }
  }

  Future<bool> checkConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _statusController.close();
  }
}
