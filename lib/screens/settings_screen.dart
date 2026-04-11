import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/budget_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/theme_provider.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../screens/login_screen.dart';
import '../screens/category_management_screen.dart';
import '../screens/budget_settings_screen.dart';
import '../screens/change_pin_screen.dart';
import '../widgets/pin_pad.dart';
import '../app.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isBiometricEnabled = false;
  bool _isBiometricSupported = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthService>();
      final supported = await auth.canAuthenticate();
      final enabled = await auth.isBiometricEnabled();
      setState(() {
        _isBiometricSupported = supported;
        _isBiometricEnabled = enabled;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear All Data',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'This will permanently delete all expenses. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger, foregroundColor: Colors.white),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<ExpenseProvider>().clearAll();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('All data cleared'),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _exportDatabase() async {
    final dbFile = await DatabaseService().getDatabaseFile();
    if (await dbFile.exists()) {
      await Share.shareXFiles(
        [XFile(dbFile.path)],
        text: 'SpendWise AI Database Export (${DateTime.now().toLocal()})',
      );
    }
  }

  Future<void> _importDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Import Database',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'Warning: This will completely replace your current database and restart your session. Ensure you have backed up your current data. Proceed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger, foregroundColor: Colors.white),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        FilePickerResult? result = await FilePicker.pickFiles();
        if (result != null && result.files.single.path != null) {
          File file = File(result.files.single.path!);
          await DatabaseService().importDatabase(file);
          
          if (!mounted) return;
          await context.read<ExpenseProvider>().reloadData();
          await context.read<BudgetProvider>().reloadData();
          
          _showToast('Database imported successfully!', isError: false);
          
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainShell()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) _showToast('Failed to import database: $e', isError: true);
      }
    }
  }

  Future<void> _changePin() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChangePinScreen()),
    );
  }

  Future<void> _toggleBiometrics(bool enabled) async {
    if (!enabled) {
      await context.read<AuthService>().setBiometricEnabled(false);
      setState(() => _isBiometricEnabled = false);
      return;
    }

    final isCorrect = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            leading: const BackButton(),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: PinPad(
            title: 'Verify PIN',
            subtitle: 'Enter Admin PIN to enable Face ID',
            onCompleted: (pin) async {
              final auth = context.read<AuthService>();
              final valid = await auth.loginWithPin('admin', pin);
              Navigator.pop(context, valid);
            },
          ),
        ),
      ),
    );

    if (isCorrect == true && mounted) {
      final auth = context.read<AuthService>();
      final authenticated = await auth.authenticateWithBiometrics();
      if (authenticated) {
        await auth.setBiometricEnabled(true);
        setState(() => _isBiometricEnabled = true);
        _showToast('Face ID enabled!', isError: false);
      }
    } else if (isCorrect == false && mounted) {
      _showToast('Incorrect PIN', isError: true);
    }
  }

  void _showToast(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.danger : AppTheme.accent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: isDark ? Colors.amber : Colors.blueGrey,
                ),
                onPressed: () {
                  themeProvider.setThemeMode(
                    isDark ? ThemeMode.light : ThemeMode.dark,
                  );
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          const SizedBox(height: 12),
          const _SectionLabel(label: 'Limits & Budget 💰'),
          
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet_outlined,
                    color: AppTheme.primary, size: 20),
              ),
              title: const Text('Budget Settings',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              subtitle: const Text('Set monthly and daily spend limits',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.primary),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BudgetSettingsScreen()),
              ),
            ),
          ).animate().fadeIn(delay: 200.ms),


          const SizedBox(height: 28),
          const _SectionLabel(label: 'Notifications & Testing'),

          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notifications_active_outlined,
                    color: AppTheme.primary, size: 20),
              ),
              title: Text('Test Weekly Summary',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyLarge?.color)),
              subtitle: const Text('Show a notification with your weekly spend',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.primary),
              onTap: () => context.read<ExpenseProvider>().triggerWeeklySummary(),
            ),
          ).animate().fadeIn(delay: 280.ms),

          const SizedBox(height: 28),
          const SizedBox(height: 28),
          const _SectionLabel(label: 'Data & Categories 📊'),

          // Manage Categories
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.category_rounded,
                    color: AppTheme.primary, size: 20),
              ),
              title: const Text('Manage Categories',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              subtitle: const Text('Add or edit your expense categories',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.primary),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoryManagementScreen()),
              ),
            ),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 12),

          // Export
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.ios_share_rounded,
                    color: AppTheme.accent, size: 20),
              ),
              title: const Text('Export Database',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              subtitle: const Text('Share your data as a database file',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.accent),
              onTap: _exportDatabase,
            ),
          ).animate().fadeIn(delay: 310.ms),

          const SizedBox(height: 12),

          // Import
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.download_rounded,
                    color: AppTheme.primary, size: 20),
              ),
              title: const Text('Import Database',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              subtitle: const Text('Restore data from a .db file',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.primary),
              onTap: _importDatabase,
            ),
          ).animate().fadeIn(delay: 315.ms),

          const SizedBox(height: 12),

          // Clear all
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_forever_rounded,
                    color: AppTheme.danger, size: 20),
              ),
              title: const Text('Clear All Data',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.danger)),
              subtitle: const Text('Permanently delete all expenses',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.danger),
              onTap: _clearAll,
            ),
          ).animate().fadeIn(delay: 320.ms),

          const SizedBox(height: 28),
          const _SectionLabel(label: 'Security & Access 🛡️'),

          // Security (Change PIN)
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lock_outline_rounded,
                    color: AppTheme.primary, size: 20),
              ),
              title: const Text('Update PIN',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              subtitle: const Text('Change your admin access PIN',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.primary),
              onTap: _changePin,
            ),
          ).animate().fadeIn(delay: 330.ms),

          const SizedBox(height: 12),

          if (_isBiometricSupported) ...[
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: SwitchListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                secondary: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.face_unlock_rounded,
                      color: AppTheme.accent, size: 20),
                ),
                title: const Text('Face ID / Biometrics',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                subtitle: const Text('Login securely with biometrics',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                value: _isBiometricEnabled,
                activeColor: AppTheme.accent,
                onChanged: _toggleBiometrics,
              ),
            ).animate().fadeIn(delay: 335.ms),
            const SizedBox(height: 12),
          ],

          // Logout
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.logout_rounded,
                    color: AppTheme.textMuted, size: 20),
              ),
              title: const Text('Logout',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              onTap: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
            ),
          ).animate().fadeIn(delay: 340.ms),

          const SizedBox(height: 28),
          const _SectionLabel(label: 'Coming Soon 🚀'),
          Opacity(
            opacity: 0.5,
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const ListTile(
                leading: Icon(Icons.cloud_upload_outlined),
                title: Text('Cloud Sync', style: TextStyle(fontSize: 14)),
                subtitle: Text('Sync data across devices', style: TextStyle(fontSize: 12)),
              ),
            ),
          ),

          const SizedBox(height: 48),
          Center(
            child: Column(
              children: [
                Image.asset('assets/images/app_icon.png', width: 40, height: 40),
                const SizedBox(height: 12),
                Text('Wise Expense v1.0.0',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted.withOpacity(0.6))),
                const SizedBox(height: 4),
                Text('Crafted with ❤️ for finance tracking',
                    style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textMuted.withOpacity(0.4))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(label,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMuted,
              letterSpacing: 0.8)),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  const _SettingsCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14,
                      color: Theme.of(context).textTheme.bodyLarge?.color)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
