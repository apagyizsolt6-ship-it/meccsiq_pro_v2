/*
===========================================
MeccsIQ Pro v2.0
Build: #001
Version: v2.0.0
File: app.dart
===========================================
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'navigation/main_navigation_screen.dart';

class MeccsIQApp extends StatelessWidget {
  const MeccsIQApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MeccsIQ Pro',

      theme: AppTheme.lightTheme,

      darkTheme: AppTheme.darkTheme,

      themeMode: themeProvider.themeMode,

      home: const MainNavigationScreen(),
    );
  }
}
