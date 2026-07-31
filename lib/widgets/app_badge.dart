/*
===========================================
MeccsIQ Pro v2.0
Build: #005
Version: v2.0.0
File: app_badge.dart
===========================================
*/

import 'package:flutter/material.dart';

class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.text,
    required this.color,
    this.icon,
  });

  final String text;
  final Color color;
  final IconData? icon;

  factory AppBadge.ai(int score) {
    return AppBadge(
      text: "AI $score",
      color: _aiColor(score),
      icon: Icons.psychology,
    );
  }

  factory AppBadge.live() {
    return const AppBadge(
      text: "LIVE",
      color: Colors.red,
      icon: Icons.circle,
    );
  }

  factory AppBadge.value() {
    return const AppBadge(
      text: "VALUE",
      color: Colors.orange,
      icon: Icons.trending_up,
    );
  }

  factory AppBadge.favorite() {
    return const AppBadge(
      text: "KEDVENC",
      color: Colors.amber,
      icon: Icons.star,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [

          if (icon != null)
            Icon(
              icon,
              size: 14,
              color: color,
            ),

          if (icon != null)
            const SizedBox(width: 5),

          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static Color _aiColor(int score) {
    if (score >= 90) {
      return Colors.green;
    }

    if (score >= 75) {
      return Colors.orange;
    }

    return Colors.red;
  }
}
