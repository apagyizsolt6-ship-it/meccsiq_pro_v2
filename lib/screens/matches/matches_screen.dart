import 'package:flutter/material.dart';
import '../../services/sports_db_service.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final SportsDbService _sportsDbService = SportsDbService();
  late Future<Map<String, dynamic>?> _liveMatchesFuture;

  @override
  void initState() {
    super.initState();
    _liveMatchesFuture = _sportsDbService.getLiveMatches();
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
          final matches = data['events'] as List<dynamic>? ?? [];

          if (matches.isEmpty) {
            return const Center(child: Text('Nincsenek mérkőzések jelenleg.'));
          }

          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              final homeTeam = match['strHomeTeam'] ?? 'Hazai csapat';
              final awayTeam = match['strAwayTeam'] ?? 'Vendég csapat';
              final league = match['strLeague'] ?? 'Bajnokság';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.sports_soccer, color: Colors.blue),
                  title: Text('$homeTeam vs $awayTeam', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(league),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
