/*
===========================================
MeccsIQ Pro v2.0
Build: #005
Version: v2.0.0
File: app_divider.dart
===========================================
*/

import 'package:flutter/material.dart';

class AppDivider extends StatelessWidget {
  const AppDivider({
    super.key,
    this.indent = 0,
    this.endIndent = 0,
    this.height = 24,
    this.thickness = .6,
  });

  final double indent;
  final double endIndent;
  final double height;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: height,
      thickness: thickness,
      indent: indent,
      endIndent: endIndent,
      color: Theme.of(context).dividerColor.withOpacity(.25),
    );
  }
}
