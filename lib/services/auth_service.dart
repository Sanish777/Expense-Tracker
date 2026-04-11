import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'database_service.dart';

class AuthService {
  final LocalAuthentication _auth = LocalAuthentication();
  final DatabaseService _db;
  
  // Master PIN hardcoded as requested
  static const String masterPin = '9999';

  AuthService(this._db);

  Future<bool> isBiometricEnabled() async {
    final val = await _db.getSetting('is_biometric_enabled');
    return val == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _db.saveSetting('is_biometric_enabled', enabled.toString());
  }

  Future<bool> canAuthenticate() async {
    return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate to access SpendWise AI',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      print('Biometric auth error: $e');
      return false;
    }
  }

  /// Validates standard user PIN
  Future<bool> loginWithPin(String username, String pin) async {
    return await _db.verifyPassword(username, pin);
  }

  /// Validates the master PIN
  Future<bool> loginWithMasterPin(String pin) async {
    return pin == masterPin;
  }

  /// Admin recovery: resets the admin PIN to the provided new PIN
  Future<void> resetAdminPin(String newPin) async {
    await _db.updatePassword('admin', newPin);
  }
}
