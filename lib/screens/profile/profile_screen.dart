import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/theme_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text(
          'profil',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 12),
          const Center(
            child: CircleAvatar(
              radius: 45,
              backgroundColor: Color(0xFFE2E8F0),
              child: Icon(
                Icons.person,
                size: 50,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'meccsiq pro',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              'version 2.0.0 build #002',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette_outlined, size: 20, color: Colors.blueAccent),
                  title: const Text('megjelenés', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  subtitle: const Text('világos / sötét mód', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                  onTap: () {
                    _showThemeBottomSheet(context, themeProvider);
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.key_outlined, size: 20, color: Colors.blueAccent),
                  title: const Text('api beállítások', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  subtitle: const Text('statpal • thesportsdb • sportmonks • gemini', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                  onTap: () {
                    _showApiSettingsBottomSheet(context);
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.info_outline, size: 20, color: Colors.blueAccent),
                  title: const Text('névjegy', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeBottomSheet(BuildContext context, ThemeProvider themeProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'megjelenés kiválasztása',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.brightness_auto),
                title: const Text('rendszer alapú', style: TextStyle(fontSize: 13)),
                onTap: () {
                  themeProvider.setTheme(ThemeMode.system);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.light_mode_outlined),
                title: const Text('világos mód', style: TextStyle(fontSize: 13)),
                onTap: () {
                  themeProvider.setTheme(ThemeMode.light);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode_outlined),
                title: const Text('sötét mód', style: TextStyle(fontSize: 13)),
                onTap: () {
                  themeProvider.setTheme(ThemeMode.dark);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showApiSettingsBottomSheet(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    
    final statpalController = TextEditingController(text: prefs.getString('statpal_key') ?? '');
    final sportsdbController = TextEditingController(text: prefs.getString('sportsdb_key') ?? '');
    final sportmonksController = TextEditingController(text: prefs.getString('sportmonks_key') ?? '');
    final geminiController = TextEditingController(text: prefs.getString('gemini_key') ?? ''); // + Google Gemini kulcs controller

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'api kulcsok beállítása',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: statpalController,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'statpal api kulcs',
                    labelStyle: TextStyle(fontSize: 12),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: sportsdbController,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'thesportsdb api kulcs',
                    labelStyle: TextStyle(fontSize: 12),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: sportmonksController,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'sportmonks api kulcs',
                    labelStyle: TextStyle(fontSize: 12),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: geminiController,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'google gemini api kulcs',
                    labelStyle: TextStyle(fontSize: 12),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      await prefs.setString('statpal_key', statpalController.text);
                      await prefs.setString('sportsdb_key', sportsdbController.text);
                      await prefs.setString('sportmonks_key', sportmonksController.text);
                      await prefs.setString('gemini_key', geminiController.text); // Mentjük a Gemini kulcsot is

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('api kulcsok sikeresen elmentve')),
                      );
                    },
                    child: const Text('kulcsok mentése', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
