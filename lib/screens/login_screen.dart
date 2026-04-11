import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../app.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showMasterPassField = false;

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

  Future<void> _handlePasswordLogin() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) return;

    setState(() => _isLoading = true);
    final auth = context.read<AuthService>();
    
    bool success;
    if (_showMasterPassField) {
      success = await auth.loginWithMasterPassword(password);
      if (success) {
        await auth.resetAdminPassword('admin123');
        _showSuccess('Password reset to admin123. Please change it!');
      }
    } else {
      success = await auth.loginWithPassword('admin', password);
    }

    setState(() => _isLoading = false);

    if (success) {
      _enterApp();
    } else {
      _showError(_showMasterPassField ? 'Invalid Master Password' : 'Wrong Password');
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
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Logo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Image.asset('assets/images/app_icon.png', width: 80, height: 80),
              ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack),
              
              const SizedBox(height: 24),
              const Text(
                'Wise Expense',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ).animate().fadeIn(delay: 400.ms),

              const Spacer(),

              // Login card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      _showMasterPassField ? 'Reset Password' : 'Welcome Back',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: _showMasterPassField ? 'Enter Master Password' : 'Enter Admin Password',
                        prefixIcon: const Icon(Icons.lock_rounded),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handlePasswordLogin,
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(_showMasterPassField ? 'Unlock & Reset' : 'Login'),
                      ),
                    ),
                    if (!_showMasterPassField && _isBiometricEnabled) ...[
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: _handleBiometricLogin,
                        icon: const Icon(Icons.face_unlock_rounded),
                        label: const Text('Login with Face ID'),
                      ),
                    ],
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() => _showMasterPassField = !_showMasterPassField),
                      child: Text(
                        _showMasterPassField ? 'Back to Login' : 'Forgot Password?',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    ),
                  ],
                ),
              ).animate().slideY(begin: 0.2, delay: 600.ms).fadeIn(),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
