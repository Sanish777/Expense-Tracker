import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class PinPad extends StatefulWidget {
  final String title;
  final String? subtitle;
  final int length;
  final bool showBiometrics;
  final VoidCallback? onBiometricsTap;
  final ValueChanged<String> onCompleted;
  final Widget? headerLogo;

  const PinPad({
    super.key,
    required this.title,
    this.subtitle,
    this.length = 4,
    this.showBiometrics = false,
    this.onBiometricsTap,
    required this.onCompleted,
    this.headerLogo,
  });

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _pin = '';

  void _onDigitTapped(String digit) {
    if (_pin.length < widget.length) {
      setState(() {
        _pin += digit;
      });
      if (_pin.length == widget.length) {
        // give a tiny delay to show the last dot filled
        Future.delayed(const Duration(milliseconds: 150), () {
          widget.onCompleted(_pin);
        });
      }
    }
  }

  void _onBackspaceTapped() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }
  
  void clear() {
    setState(() {
      _pin = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SafeArea(
      child: Column(
        children: [
          const Spacer(),
          if (widget.headerLogo != null) ...[
            widget.headerLogo!,
            const SizedBox(height: 32),
          ],
          Text(
            widget.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ).animate().fadeIn(),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.subtitle!,
              style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
            ).animate().fadeIn(),
          ],
          const SizedBox(height: 32),
          // PIN Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.length, (index) {
              bool isFilled = index < _pin.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled 
                      ? (isDark ? Colors.white : Colors.black)
                      : (isDark ? Colors.white12 : Colors.black12),
                ),
              ).animate(target: isFilled ? 1 : 0)
               .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.1, 1.1))
               .tint(color: isDark ? Colors.white : Colors.black);
            }),
          ),
          const Spacer(flex: 2),
          // Keypad
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 1.2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildDigitButton('1'), _buildDigitButton('2'), _buildDigitButton('3'),
                _buildDigitButton('4'), _buildDigitButton('5'), _buildDigitButton('6'),
                _buildDigitButton('7'), _buildDigitButton('8'), _buildDigitButton('9'),
                _buildIconButton(
                  widget.showBiometrics ? Icons.face_unlock_rounded : null,
                  onTap: widget.showBiometrics ? widget.onBiometricsTap : null,
                ),
                _buildDigitButton('0'),
                _buildIconButton(Icons.backspace_outlined, onTap: _onBackspaceTapped),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDigitButton(String digit) {
    return InkWell(
      onTap: () => _onDigitTapped(digit),
      customBorder: const CircleBorder(),
      splashColor: AppTheme.primary.withOpacity(0.1),
      child: Center(
        child: Text(
          digit,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData? icon, {VoidCallback? onTap}) {
    if (icon == null) return const SizedBox();
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      splashColor: AppTheme.primary.withOpacity(0.1),
      child: Center(
        child: Icon(icon, size: 28, color: AppTheme.textMuted),
      ),
    );
  }
}
