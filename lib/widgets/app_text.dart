/*
===========================================
MeccsIQ Pro v2.0
Build: #005
Version: v2.0.0
File: app_text.dart
===========================================
*/

import 'package:flutter/material.dart';

class AppText extends StatelessWidget {
  const AppText(
    this.text, {
    super.key,
    this.color,
    this.size = 14,
    this.weight = FontWeight.w600,
    this.maxLines,
    this.overflow,
    this.align,
  });

  final String text;
  final Color? color;
  final double size;
  final FontWeight weight;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? align;

  factory AppText.title(
    String text, {
    Color? color,
  }) {
    return AppText(
      text,
      size: 22,
      weight: FontWeight.bold,
      color: color,
    );
  }

  factory AppText.subtitle(
    String text, {
    Color? color,
  }) {
    return AppText(
      text,
      size: 16,
      weight: FontWeight.bold,
      color: color,
    );
  }

  factory AppText.body(
    String text, {
    Color? color,
  }) {
    return AppText(
      text,
      size: 13,
      weight: FontWeight.w600,
      color: color,
    );
  }

  factory AppText.caption(
    String text, {
    Color? color,
  }) {
    return AppText(
      text,
      size: 11,
      weight: FontWeight.w600,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: align,
      style: TextStyle(
        color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
        fontSize: size,
        fontWeight: weight,
      ),
    );
  }
}
