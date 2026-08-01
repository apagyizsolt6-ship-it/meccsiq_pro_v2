import 'package:flutter/material.dart';
import '../../models/match_model.dart';
import '../../models/league_model.dart';
import '../../models/team_model.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final otpLeague = LeagueModel(id: 1, name: 'OTP Bank Liga', country: 'Magyarország');
    final laLiga = LeagueModel(id: 2, name: 'La Liga', country: 'Spanyolország');
    
    final matches = [
      // OTP Bank Liga meccsek
      MatchModel(
        id: 1,
        league: otpLeague,
        homeTeam: TeamModel(id: 1, name: 'Ferencváros'),
        awayTeam: TeamModel(id: 2, name: 'Újpest'),
        kickoff: DateTime.now().subtract(const Duration(hours: 2)),
        homeScore: 2,
        awayScore: 1,
        status: MatchStatus.finished,
      ),
      MatchModel(
        id: 2,
        league: otpLeague,
        homeTeam: TeamModel(id: 3, name: 'Puskás Akadémia'),
        awayTeam: TeamModel(id: 4, name: 'DVSC'),
        kickoff: DateTime.now(),
        homeScore: 0,
        awayScore: 0,
        status: MatchStatus.live,
      ),
      MatchModel(
        id: 3,
        league: otpLeague,
        homeTeam: TeamModel(id: 5, name: 'MTK Budapest'),
        awayTeam: TeamModel(id: 6, name: 'ZTE FC'),
        kickoff: DateTime.now().add(const Duration(hours: 2)),
        homeScore: null,
        awayScore: null,
        status: MatchStatus.notStarted,
      ),
      // La Liga meccsek
      MatchModel(
        id: 4,
        league: laLiga,
        homeTeam: TeamModel(id: 7, name: 'Real Madrid'),
        awayTeam: TeamModel(id: 8, name: 'Barcelona'),
        kickoff: DateTime.now().add(const Duration(hours: 4)),
        homeScore: null,
        awayScore: null,
        status: MatchStatus.notStarted,
      ),
      MatchModel(
        id: 5,
        league: laLiga,
        homeTeam: TeamModel(id: 9, name: 'Atlético Madrid'),
        awayTeam: TeamModel(id: 10, name: 'Sevilla'),
        kickoff: DateTime.now().add(const Duration(hours: 6)),
        homeScore: null,
        awayScore: null,
        status: MatchStatus.notStarted,
      ),
    ];

    // Ligák szerinti csoportosítás
    final otpMatches = matches.where((m) => m.league.id == 1).toList();
    final spanishMatches = matches.where((m) => m.league.id == 2).toList();

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
          // Magyarország lenyitható szekció
          _buildLeagueSection('MAGYARORSZÁG: OTP Bank Liga', otpMatches),
          const SizedBox(height: 8),
          // Spanyolország lenyitható szekció
          _buildLeagueSection('SPANYOLORSZÁG: La Liga', spanishMatches),
        ],
      ),
    );
  }

  Widget _buildLeagueSection(String title, List<MatchModel> leagueMatches) {
    return Container(
      color: Colors.white,
      child: ExpansionTile(
        initiallyExpanded: true,
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        title: Row(
          children: [
            const Icon(Icons.sports_soccer, size: 16, color: Colors.blueAccent),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
          ],
        ),
        children: leagueMatches.map((match) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Text(
                    match.isLive 
                        ? 'LIVE' 
                        : (match.isFinished 
                            ? 'Vége' 
                            : '${match.kickoff.hour.toString().padLeft(2, '0')}:${match.kickoff.minute.toString().padLeft(2, '0')}'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: match.isLive ? Colors.redAccent : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 8),
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
        )).toList(),
      ),
    );
  }
}
