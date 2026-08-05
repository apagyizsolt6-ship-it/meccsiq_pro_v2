/*
===========================================
MeccsIQ Pro v2.0
Build: #004
Version: v2.0.0
File: home_screen.dart
===========================================
*/

import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MeccsIQ Pro',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Üdv újra! 👋',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Készen állsz a mai mérkőzések elemzésére?',
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),

          // AI Top Tippek
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE3F2FD),
                child: Icon(Icons.auto_awesome, color: Colors.blueAccent),
              ),
              title: const Text(
                'AI Top Tippek',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('A mai legjobb ajánlások'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Ide később navigáció az AI tabra, ha kell
              },
            ),
          ),

          const SizedBox(height: 12),

          // API állapot
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.cloud_done, color: Colors.green),
              ),
              title: const Text(
                'API állapot',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'StatPal • TheSportsDB • SportMonks',
              ),
              trailing: const Icon(
                Icons.check_circle,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
