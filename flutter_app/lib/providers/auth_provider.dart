import 'package:flutter/foundation.dart';
import 'package:raffle_app/models/user.dart';
import 'package:raffle_app/services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get userRole => _user?.role;

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    _isAuthenticated = await _authService.isAuthenticated();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String phone, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(phone, password);
      
      if (result['success'] == true) {
        _user = result['user'];
        _isAuthenticated = true;
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Login error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authService.logout();
    
    _user = null;
    _isAuthenticated = false;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
