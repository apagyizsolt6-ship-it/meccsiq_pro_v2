/*
===========================================
MeccsIQ Pro v2.0
Build: #005
Version: v2.0.0
File: loading_card.dart
===========================================
*/

import 'package:flutter/material.dart';

import 'app_card.dart';

class LoadingCard extends StatelessWidget {
  const LoadingCard({
    super.key,
    this.height = 90,
    this.margin = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 6,
    ),
  });

  final double height;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: margin,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: height,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
