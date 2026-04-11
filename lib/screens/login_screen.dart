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
  bool _obscurePassword = true;

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
    
    try {
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

      if (success) {
        _enterApp();
      } else {
        _showError(_showMasterPassField ? 'Invalid Master Password' : 'Wrong Password');
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
              const Spacer(),
              // Logo (Tinted based on theme)
              Image.asset(
                'assets/images/app_icon.png',
                width: 100,
                height: 100,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                colorBlendMode: BlendMode.srcIn,
              )
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(delay: 1500.ms, duration: 2000.ms, color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.black12),
              
              const SizedBox(height: 24),
              const Text(
                'Wise Expense',
                style: TextStyle(
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
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: _showMasterPassField ? 'Enter Master Password' : 'Enter Admin Password',
                        prefixIcon: const Icon(Icons.lock_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handlePasswordLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                          foregroundColor: Theme.of(context).brightness == Brightness.dark
                              ? Colors.black
                              : Colors.white,
                        ),
                        child: _isLoading 
                          ? CircularProgressIndicator(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.black
                                  : Colors.white)
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
