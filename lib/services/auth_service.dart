import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'database_service.dart';

class AuthService {
  final LocalAuthentication _auth = LocalAuthentication();
  final DatabaseService _db;
  
  // Master password hardcoded as requested
  static const String masterPassword = 'spendwise_master_2024';

  AuthService(this._db);

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

  Future<bool> loginWithPassword(String username, String password) async {
    return await _db.verifyPassword(username, password);
  }

  Future<bool> loginWithMasterPassword(String password) async {
    return password == masterPassword;
  }

  Future<void> resetAdminPassword(String newPassword) async {
    await _db.updatePassword('admin', newPassword);
  }
}
