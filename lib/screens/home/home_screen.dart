/*
===========================================
MeccsIQ Pro v2.0
Build: #003
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

          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.auto_awesome),
              ),
              title: const Text(
                'AI Top Tippek',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                'A mai legjobb ajánlások',
              ),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.document_scanner),
              ),
              title: const Text(
                'Szelvény beolvasása',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                'OCR elemzés indítása',
              ),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.cloud_done),
              ),
              title: const Text(
                'API állapot',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                'StatPal • TheSportsDB • SportMonks',
              ),
              trailing: Icon(
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
