/*
===========================================
MeccsIQ Pro v2.0
Build: #002
Version: v2.0.0
File: profile_screen.dart
===========================================
*/

import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SizedBox(height: 24),

          Icon(
            Icons.account_circle,
            size: 90,
          ),

          SizedBox(height: 16),

          Center(
            child: Text(
              'MeccsIQ Pro',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          SizedBox(height: 8),

          Center(
            child: Text(
              'Version 2.0.0',
              style: TextStyle(
                fontSize: 15,
              ),
            ),
          ),

          SizedBox(height: 40),

          ListTile(
            leading: Icon(Icons.palette_outlined),
            title: Text('Megjelenés'),
            subtitle: Text('Világos / Sötét mód'),
            trailing: Icon(Icons.chevron_right),
          ),

          Divider(),

          ListTile(
            leading: Icon(Icons.key_outlined),
            title: Text('API beállítások'),
            subtitle: Text('StatPal • TheSportsDB • SportMonks'),
            trailing: Icon(Icons.chevron_right),
          ),

          Divider(),

          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Névjegy'),
            trailing: Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
