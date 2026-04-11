import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../widgets/pin_pad.dart';
import '../theme/app_theme.dart';
import '../app.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _pinController = TextEditingController();
  bool _isLoading = false;
  bool _showMasterPinField = false;
  bool _obscurePin = true;

  bool _isBiometricSupported = false;
  bool _isBiometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricStatus();
  }

  Future<void> _checkBiometricStatus() async {
    final auth = context.read<AuthService>();
    final supported = await auth.canAuthenticate();
    final enabled = await auth.isBiometricEnabled();
    setState(() {
      _isBiometricSupported = supported;
      _isBiometricEnabled = enabled;
    });
  }

  Future<void> _handlePinLogin() async {
    final pin = _pinController.text.trim();
    if (pin.isEmpty) return;

    setState(() => _isLoading = true);
    
    try {
      final auth = context.read<AuthService>();
      
      bool success;
      if (_showMasterPinField) {
        success = await auth.loginWithMasterPin(pin);
        if (success) {
          await auth.resetAdminPin('1234');
          _showSuccess('PIN reset to 1234. Please change it!');
        }
      } else {
        success = await auth.loginWithPin('admin', pin);
      }

      if (success) {
        _enterApp();
      } else {
        _showError(_showMasterPinField ? 'Invalid Master PIN' : 'Wrong PIN');
      }
    } catch (e) {
      _showError('Login error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleBiometricLogin() async {
    final auth = context.read<AuthService>();
    final success = await auth.authenticateWithBiometrics();
    if (success) _enterApp();
  }

  void _enterApp() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.danger),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.accent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SizedBox(
        width: double.infinity,
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
// ── Login UI ───────────────────────────
              Expanded(
                child: PinPad(
                  headerLogo: Image.asset(
                    Theme.of(context).brightness == Brightness.dark
                        ? 'assets/images/app_icon_light.png'
                        : 'assets/images/app_icon_dark.png',
                    width: 80,
                    height: 80,
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .shimmer(delay: 1500.ms, duration: 2000.ms, 
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.black12),
                  title: _isLoading 
                      ? 'Verifying...'
                      : (_showMasterPinField ? 'Enter Master PIN' : 'Enter your PIN'),
                  subtitle: _showMasterPinField ? 'Used to reset admin PIN' : null,
                  showBiometrics: !_showMasterPinField && _isBiometricEnabled,
                  onBiometricsTap: _handleBiometricLogin,
                  onCompleted: (pin) {
                    _pinController.text = pin;
                    _handlePinLogin();
                  },
                ).animate().fadeIn(delay: 200.ms),
              ),

              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: TextButton(
                  onPressed: () {
                    // Slight delay to allow focus/pin clearing
                    setState(() {
                      _showMasterPinField = !_showMasterPinField;
                      _pinController.clear();
                    });
                  },
                  child: Text(
                    _showMasterPinField ? 'Back to Login' : 'Forgot PIN?',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
