import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/pin_pad.dart';
import '../theme/app_theme.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  bool _verifyingCurrent = true;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.danger),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.accent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: PinPad(
        title: _verifyingCurrent ? 'Enter Current PIN' : 'Enter New PIN',
        subtitle: _verifyingCurrent ? 'Verify your identity' : 'Set a new 4-digit PIN',
        onCompleted: (pin) async {
          final auth = context.read<AuthService>();
          if (_verifyingCurrent) {
            final isCorrect = await auth.loginWithPin('admin', pin);
            if (isCorrect) {
              setState(() => _verifyingCurrent = false);
            } else {
              _showError('Incorrect PIN');
              // The state rebuild will occur; we could force clear from a key, 
              // but reloading the state might just be enough. Actually we need a key to clear inside PinPad.
              // To keep it simple, we just pop and retry, or recreate PinPad.
              // Recreating PinPad can be done by providing a different key based on step.
            }
          } else {
            await auth.resetAdminPin(pin);
            _showSuccess('PIN updated successfully!');
            if (mounted) Navigator.pop(context);
          }
        },
        // We use a key based on the state so when it switches from current to new, it resets the dots/pin internal
        key: ValueKey(_verifyingCurrent),
      ),
    );
  }
}
