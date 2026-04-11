import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class InsightCard extends StatelessWidget {
  final String tip;
  final int index;

  const InsightCard({super.key, required this.tip, required this.index});

  @override
  Widget build(BuildContext context) {
    final gradients = [
      [const Color(0xFF6C63FF), const Color(0xFF4ECDC4)],
      [const Color(0xFFFF6B6B), const Color(0xFFFF8C42)],
      [const Color(0xFF00D4BE), const Color(0xFF6C63FF)],
      [const Color(0xFFFFE66D), const Color(0xFFFF8C42)],
    ];
    final grad = gradients[index % gradients.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: grad),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: grad),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(Icons.lightbulb_outline_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tip,
                style: const TextStyle(fontSize: 13.5, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
