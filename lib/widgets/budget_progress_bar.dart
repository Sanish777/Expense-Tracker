import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BudgetProgressBar extends StatelessWidget {
  final double spent;
  final double limit;

  const BudgetProgressBar({
    super.key,
    required this.spent,
    required this.limit,
  });

  @override
  Widget build(BuildContext context) {
    final pct = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
    final isOver = spent > limit && limit > 0;
    final color = isOver
        ? AppTheme.danger
        : pct > 0.8
            ? AppTheme.warning
            : AppTheme.accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              limit > 0
                  ? 'Rs. ${spent.toStringAsFixed(0)} / Rs. ${limit.toStringAsFixed(0)}'
                  : 'No budget set',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500),
            ),
            if (limit > 0)
              Text(
                '${(pct * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 10,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: pct,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isOver
                        ? const LinearGradient(colors: [AppTheme.danger, Color(0xFFFF8B8B)])
                        : AppTheme.rainbowGradient,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: (isOver ? AppTheme.danger : AppTheme.primary)
                            .withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
