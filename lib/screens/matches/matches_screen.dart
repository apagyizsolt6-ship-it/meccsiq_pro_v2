import 'package:flutter/material.dart';
import '../../models/match_model.dart';
import '../../models/league_model.dart';
import '../../models/team_model.dart';
import '../../services/statpal_service.dart';
import 'widgets/match_tile.dart';
import 'match_detail_screen.dart';

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

          // Itt feldolgozhatjuk a StatPal-tól kapott JSON választ a meccsekre.
          // (A válasz struktúrájától függően építjük fel a MatchModel listát)
          
          return ListView(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('StatPal API adatok sikeresen betöltve.', style: TextStyle(color: Colors.grey)),
              ),
            ],
          );
        },
      ),
    );
  }
}
