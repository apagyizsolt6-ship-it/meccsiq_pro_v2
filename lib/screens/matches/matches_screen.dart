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
        title: const Text('Élő Foci Eredmények', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
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
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Nincsenek elérhető mérkőzések.', style: TextStyle(fontSize: 13)));
          }

          final data = snapshot.data!;
          final allEvents = data['events'] as List<dynamic>? ?? [];

          // Csak a focimeccsek szűrése
          final matches = allEvents.where((match) {
            final sport = match['strSport']?.toString().toLowerCase() ?? '';
            return sport == 'soccer' || (sport.contains('football') && !sport.contains('american'));
          }).toList();

          if (matches.isEmpty) {
            return const Center(child: Text('Nincsenek focimeccsek ezen a napon.', style: TextStyle(fontSize: 13)));
          }

          // Csoportosítás bajnokságok szerint (Eredmények.com stílus)
          final Map<String, List<dynamic>> groupedMatches = {};
          for (var match in matches) {
            final league = match['strLeague'] ?? 'Egyéb bajnokság';
            groupedMatches.putIfAbsent(league, () => []).add(match);
          }

          final leagues = groupedMatches.keys.toList();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: leagues.length,
            itemBuilder: (context, leagueIndex) {
              final leagueName = leagues[leagueIndex];
              final leagueMatches = groupedMatches[leagueName]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bajnokság fejléc (Eredmények.com sötétebb/szürke sáv stílus)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    color: const Color(0xFFE2E8F0),
                    child: Row(
                      children: [
                        const Icon(Icons.sports_soccer, size: 14, color: Colors.black54),
                        const SizedBox(width: 6),
                        Text(
                          leagueName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Meccsek listája az adott bajnokságon belül
                  ...leagueMatches.map((match) {
                    final homeTeam = match['strHomeTeam'] ?? 'Hazai';
                    final awayTeam = match['strAwayTeam'] ?? 'Vendég';
                    final homeScore = match['intHomeScore'] ?? '-';
                    final awayScore = match['intAwayScore'] ?? '-';
                    final status = match['strStatus'] ?? match['strProgress'] ?? 'Élő';

                    return Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          // Státusz / Idő / Esemény állapota kisebb betűvel
                          SizedBox(
                            width: 45,
                            child: Text(
                              status,
                              style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          ),
                          // Csapatnevek (Hazai / Vendég)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  homeTeam,
                                  style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  awayTeam,
                                  style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w400),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // Eredmény számok (Eredmények.com jobb oldali oszlop stílus)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$homeScore',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$awayScore',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
