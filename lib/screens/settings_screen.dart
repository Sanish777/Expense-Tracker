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

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _monthlyController = TextEditingController();
  final _dailyController = TextEditingController();
  bool _isBiometricEnabled = false;
  bool _isBiometricSupported = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final budget = context.read<BudgetProvider>().budget;
      if (budget != null) {
        _monthlyController.text = budget.monthlyLimit.toStringAsFixed(0);
        _dailyController.text = budget.dailyLimit.toStringAsFixed(0);
      }
      
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
    _monthlyController.dispose();
    _dailyController.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    final monthly = double.tryParse(_monthlyController.text) ?? 0;
    final daily = double.tryParse(_dailyController.text) ?? 0;
    await context
        .read<BudgetProvider>()
        .saveBudget(monthlyLimit: monthly, dailyLimit: daily);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 10),
            Text('Budget saved successfully!'),
          ]),
          backgroundColor: AppTheme.accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
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

  Future<void> _changePassword() async {
    final oldController = TextEditingController();
    final newController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Admin Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current Password'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Update')),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final auth = context.read<AuthService>();
      final isOldCorrect = await auth.loginWithPassword('admin', oldController.text);
      
      if (isOldCorrect) {
        await auth.resetAdminPassword(newController.text);
        _showToast('Password updated successfully!', isError: false);
      } else {
        _showToast('Current password incorrect', isError: true);
      }
    }
  }

  Future<void> _toggleBiometrics(bool enabled) async {
    if (!enabled) {
      await context.read<AuthService>().setBiometricEnabled(false);
      setState(() => _isBiometricEnabled = false);
      return;
    }

    final passController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enable Face ID'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter admin password to enable biometric login.'),
            const SizedBox(height: 16),
            TextField(
              controller: passController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Admin Password'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Verify')),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final auth = context.read<AuthService>();
      final isCorrect = await auth.loginWithPassword('admin', passController.text);
      
      if (isCorrect) {
        final authenticated = await auth.authenticateWithBiometrics();
        if (authenticated) {
          await auth.setBiometricEnabled(true);
          setState(() => _isBiometricEnabled = true);
          _showToast('Face ID enabled!', isError: false);
        }
      } else {
        _showToast('Incorrect password', isError: true);
      }
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
      appBar: AppBar(title: const Text('Settings'),
          automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          // ── Profile card ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    image: const DecorationImage(
                      image: AssetImage('assets/images/app_icon.png'),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SpendWise User',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    SizedBox(height: 2),
                    Text('Track · Analyse · Save',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 24),
          const _SectionLabel(label: 'Budget Settings'),

          // Monthly limit
          _SettingsCard(
            icon: Icons.calendar_month_rounded,
            iconColor: AppTheme.primary,
            title: 'Monthly Limit',
            child: TextField(
              controller: _monthlyController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: 'e.g. 25000',
                prefixText: 'Rs. ',
              ),
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

          const SizedBox(height: 12),

          // Daily limit
          _SettingsCard(
            icon: Icons.today_rounded,
            iconColor: AppTheme.warning,
            title: 'Daily Limit',
            child: TextField(
              controller: _dailyController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: 'e.g. 1000',
                prefixText: 'Rs. ',
              ),
            ),
          ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveBudget,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save Budget'),
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 28),
          const _SectionLabel(label: 'Appearance'),

          // Theme toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
            child: Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                        isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: AppTheme.primary, size: 20),
                  ),
                  title: Text('Dark Mode',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14,
                          color: Theme.of(context).textTheme.bodyLarge?.color)),
                  subtitle: Text('Toggle dark/light theme',
                      style:
                          TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  value: isDark,
                  activeColor: AppTheme.primary,
                  onChanged: (v) {
                    themeProvider.setThemeMode(v ? ThemeMode.dark : ThemeMode.light);
                  },
                );
              },
            ),
          ).animate().fadeIn(delay: 250.ms),

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
          const _SectionLabel(label: 'Data'),

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
          ).animate().fadeIn(delay: 290.ms),

          const SizedBox(height: 12),

          // Biometric Toggle
          if (_isBiometricSupported)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                contentPadding: EdgeInsets.zero,
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
                title: const Text('Biometric Login',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Unlock app with Face ID',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                value: _isBiometricEnabled,
                activeColor: AppTheme.accent,
                onChanged: _toggleBiometrics,
              ),
            ).animate().fadeIn(delay: 295.ms),

          if (_isBiometricSupported) const SizedBox(height: 12),

          if (_isBiometricSupported) const SizedBox(height: 12),

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

          // Change Password
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
              title: const Text('Security',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              subtitle: const Text('Change admin password',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.primary),
              onTap: _changePassword,
            ),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 12),

          // Logout (Back to Login)
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
              subtitle: const Text('Return to login screen',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textMuted),
              onTap: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
            ),
          ).animate().fadeIn(delay: 310.ms),

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

          const SizedBox(height: 32),
          Center(
            child: Text('SpendWise AI v1.0.0',
                style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted.withOpacity(0.6))),
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
