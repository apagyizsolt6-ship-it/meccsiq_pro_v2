import 'package:flutter/material.dart';
import '../../services/statpal_service.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final StatpalService _statpalService = StatpalService();
  late Future<Map<String, dynamic>?> _liveMatchesFuture;

  @override
  void initState() {
    super.initState();
    _liveMatchesFuture = _statpalService.getLiveMatches();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Meccsek', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _liveMatchesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Hiba az adatok betöltése közben:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Nincsenek elérhető mérkőzések.'));
          }

          final data = snapshot.data!;
          // Itt nyerjük ki a meccsek listáját a JSON-ből (ha a kulcs pl. 'response' vagy 'data' vagy 'matches')
          // Állítsd be a StatPal API szerkezete szerint a megfelelő kulcsot:
          final matches = data['response'] ?? data['data'] ?? data['matches'] ?? [];

          if (matches.isEmpty) {
            return const Center(child: Text('Nincsenek élő mérkőzések jelenleg.'));
          }

          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              // Példa mezők kiolvasására (cseréld le a Valódi StatPal kulcsokra, ha szükséges):
              final homeTeam = match['home_team']?['name'] ?? match['homeTeam'] ?? 'Hazai csapat';
              final awayTeam = match['away_team']?['name'] ?? match['awayTeam'] ?? 'Vendég csapat';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.sports_soccer, color: Colors.blue),
                  title: Text('$homeTeam vs $awayTeam', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Élő mérkőzés'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
