import 'package:flutter/material.dart';
import '../../models/match_model.dart';
import '../../models/league_model.dart';
import '../../models/team_model.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sampleLeague = LeagueModel(id: 1, name: 'OTP Bank Liga', country: 'Magyarország');
    
    final matches = [
      MatchModel(
        id: 1,
        league: sampleLeague,
        homeTeam: TeamModel(id: 1, name: 'Ferencváros'),
        awayTeam: TeamModel(id: 2, name: 'Újpest'),
        kickoff: DateTime.now().subtract(const Duration(hours: 2)),
        homeScore: 2,
        awayScore: 1,
        status: MatchStatus.finished,
      ),
      MatchModel(
        id: 2,
        league: sampleLeague,
        homeTeam: TeamModel(id: 3, name: 'Puskás Akadémia'),
        awayTeam: TeamModel(id: 4, name: 'DVSC'),
        kickoff: DateTime.now(),
        homeScore: 0,
        awayScore: 0,
        status: MatchStatus.live,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Meccsek', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Liga fejléc (Eredmények.com stílus)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blueGrey.withOpacity(0.1),
            child: Row(
              children: const [
                Icon(Icons.sports_soccer, size: 16, color: Colors.blueAccent),
                SizedBox(width: 8),
                Text(
                  'MAGYARORSZÁG: OTP Bank Liga',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
              ],
            ),
          ),
          // Meccsek kártyákban
          ...matches.map((match) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Státusz / Idő
                      SizedBox(
                        width: 50,
                        child: Text(
                          match.isLive ? 'LIVE' : (match.isFinished ? 'Vége' : '21:00'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: match.isLive ? Colors.redAccent : Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Csapatok
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              match.homeTeam.name,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              match.awayTeam.name,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                      // Eredmények
                      if (match.hasScore)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${match.homeScore}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${match.awayScore}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
