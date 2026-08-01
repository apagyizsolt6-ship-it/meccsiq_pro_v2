/*
===========================================
MeccsIQ Pro v2.0
Build: #006
Version: v2.0.1
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
    TextAlign? align,
  }) {
    return AppText(
      text,
      size: 22,
      weight: FontWeight.bold,
      color: color,
      align: align,
    );
  }

  factory AppText.subtitle(
    String text, {
    Color? color,
    TextAlign? align,
  }) {
    return AppText(
      text,
      size: 16,
      weight: FontWeight.bold,
      color: color,
      align: align,
    );
  }

  factory AppText.body(
    String text, {
    Color? color,
    TextAlign? align,
  }) {
    return AppText(
      text,
      size: 13,
      weight: FontWeight.w600,
      color: color,
      align: align,
    );
  }

  factory AppText.caption(
    String text, {
    Color? color,
    TextAlign? align,
  }) {
    return AppText(
      text,
      size: 11,
      weight: FontWeight.w600,
      color: color,
      align: align,
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
