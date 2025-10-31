import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart'; // Import ApiService

// Mock user class for frontend-only implementation
class MockGoogleUser {
  final String id;
  final String displayName;
  final String email;
  final String? photoUrl;

  MockGoogleUser({
    required this.id,
    required this.displayName,
    required this.email,
    this.photoUrl,
  });
}

class AuthProvider extends ChangeNotifier {
  MockGoogleUser? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;
  String? _successMessage; // New state for success messages
  bool _isDeviceRegistering = false; // New state for device registration
  String? _visitorToken;

  MockGoogleUser? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;
  bool get isDeviceRegistering => _isDeviceRegistering;

  String? get visitorToken => _visitorToken;

  // Use singleton instance
  final ApiService _apiService = ApiService();

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    _isDeviceRegistering = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    debugPrint('[AuthProvider] Checking for existing visitorToken...');
    final prefs = await SharedPreferences.getInstance();
    _visitorToken = prefs.getString('visitorToken');

    if (_visitorToken == null) {
      debugPrint(
        '[AuthProvider] No visitorToken found. Registering new device...',
      );
      // Device not registered, perform registration
      try {
        final result = await _apiService.registerDevice();
        debugPrint('[AuthProvider] Device registration result: $result');

        // Check different possible response structures
        String? newVisitorToken;

        if (result['status'] == true && result['data'] is Map) {
          final data = result['data'] as Map<String, dynamic>;

          // Try different key formats
          newVisitorToken = data['visitor Token'] ?? data['token'];
          debugPrint('[AuthProvider] Extracted token: $newVisitorToken');
        }

        if (newVisitorToken != null && newVisitorToken.isNotEmpty) {
          await prefs.setString('visitorToken', newVisitorToken);
          _visitorToken = newVisitorToken;
          // Update the token in ApiService singleton
          _apiService.updateVisitorToken(newVisitorToken);
          _successMessage =
              result['message'] ?? 'Device registered successfully';
          debugPrint(
            '[AuthProvider] SUCCESS: New visitorToken generated and saved: $newVisitorToken',
          );
        } else {
          _error = 'Failed to extract visitor token from response';
          debugPrint(
            '[AuthProvider] FAILED: Could not extract token. Response data: ${result['data']}',
          );
        }
      } catch (e) {
        // This will now only catch network/parsing exceptions
        _error = 'Error during device registration: ${e.toString()}';
        debugPrint(
          '[AuthProvider] ERROR: An exception occurred during device registration: $_error',
        );
        _isDeviceRegistering = false;
        notifyListeners();
        return; // Stop further processing if device registration fails
      }
    } else {
      // Device already registered, set the token in ApiService
      // Update the token in our instance
      _apiService.updateVisitorToken(_visitorToken!);
      debugPrint(
        '[AuthProvider] SUCCESS: Using existing visitorToken from storage: $_visitorToken',
      );
    }

    // Fetch app settings now that we have a visitor token
    // try {
    //   final settingsResp = await _apiService.getAppSettings();
    //   if (settingsResp['status'] == true && settingsResp['data'] is Map) {
    //     _appSettings = AppSettings.fromJson(settingsResp['data']);
    //     debugPrint(
    //       '[AuthProvider] App settings loaded: '
    //       'maintenance=${_appSettings!.appMaintenanceMode}, '
    //       'androidForce=${_appSettings!.appAndroidForceUpdate}, '
    //       'iosForce=${_appSettings!.appIsoForceUpdate}',
    //     );
    //   } else {
    //     debugPrint(
    //       '[AuthProvider] Failed to load app settings: ${settingsResp['message']}',
    //     );
    //   }
    // } catch (e) {
    //   debugPrint('[AuthProvider] Exception while loading app settings: $e');
    // }

    _isDeviceRegistering = false; // Device registration complete
    _isAuthenticated = prefs.getBool('isAuthenticated') ?? false;

    if (_isAuthenticated) {
      // Restore mock user from storage
      _user = MockGoogleUser(
        id: prefs.getString('userId') ?? 'mock_user_123',
        displayName: prefs.getString('userName') ?? 'Demo User',
        email: prefs.getString('userEmail') ?? 'demo@example.com',
        photoUrl: prefs.getString('userPhoto'),
      );
    }

    notifyListeners();
  }

  // Frontend-only Google Sign-In simulation
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    try {
      // Mock successful sign-in
      _user = MockGoogleUser(
        id: 'mock_user_${DateTime.now().millisecondsSinceEpoch}',
        displayName: 'Pruthvi Kumar',
        email: 'pruthvi@example.com',
        photoUrl:
            'https://ui-avatars.com/api/?name=Pruthvi+Kumar&size=200&background=1E88E5&color=fff',
      );

      _isAuthenticated = true;

      // Save auth status and user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isAuthenticated', true);
      await prefs.setString('userId', _user!.id);
      await prefs.setString('userName', _user!.displayName);
      await prefs.setString('userEmail', _user!.email);
      if (_user!.photoUrl != null) {
        await prefs.setString('userPhoto', _user!.photoUrl!);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to sign in: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      _user = null;
      _isAuthenticated = false;

      final prefs = await SharedPreferences.getInstance();
      // Keep visitorToken, only clear user-specific data
      await prefs.remove('isAuthenticated');
      await prefs.remove('userId');
      await prefs.remove('userName');
      await prefs.remove('userEmail');
      await prefs.remove('userPhoto');

      notifyListeners();
    } catch (e) {
      _error = 'Failed to sign out: ${e.toString()}';
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }
}
