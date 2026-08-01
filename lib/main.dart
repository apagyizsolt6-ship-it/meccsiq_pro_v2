/*
===========================================
MeccsIQ Pro v2.0
Build: #001
Version: v2.0.0
File: main.dart
===========================================
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();

  runApp(
    ChangeNotifierProvider(
      create: (_) => themeProvider,
      child: const MeccsIQApp(),
    ),
  );
}
