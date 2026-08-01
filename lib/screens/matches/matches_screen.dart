import 'package:flutter/material.dart';
import '../../models/match_model.dart';
import '../../models/league_model.dart';
import '../../models/team_model.dart';
import 'widgets/match_tile.dart';
import 'match_detail_screen.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final otpLeague = LeagueModel(id: 1, name: 'OTP Bank Liga', country: 'Magyarország');
    final laLiga = LeagueModel(id: 2, name: 'La Liga', country: 'Spanyolország');
    
    final matches = [
      MatchModel(
        id: 1,
        league: otpLeague,
        homeTeam: TeamModel(id: 1, name: 'Ferencváros'),
        awayTeam: TeamModel(id: 2, name: 'Újpest'),
        kickoff: DateTime.now().subtract(const Duration(hours: 2)),
        homeScore: 2,
        awayScore: 1,
        status: MatchStatus.finished,
        aiScore: 85,
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
        aiScore: 92,
      ),
      MatchModel(
        id: 3,
        league: laLiga,
        homeTeam: TeamModel(id: 5, name: 'Real Madrid'),
        awayTeam: TeamModel(id: 6, name: 'Barcelona'),
        kickoff: DateTime.now().add(const Duration(hours: 4)),
        status: MatchStatus.notStarted,
        aiScore: 78,
      ),
    ];

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
          _buildLeagueSection('MAGYARORSZÁG: OTP Bank Liga', otpMatches, context),
          const SizedBox(height: 8),
          _buildLeagueSection('SPANYOLORSZÁG: La Liga', spanishMatches, context),
        ],
      ),
    );
  }

  Widget _buildLeagueSection(String title, List<MatchModel> leagueMatches, BuildContext context) {
    return Container(
      color: Colors.white,
      child: ExpansionTile(
        initiallyExpanded: true,
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
        children: leagueMatches.map((match) {
          final timeStr = '${match.kickoff.hour.toString().padLeft(2, '0')}:${match.kickoff.minute.toString().padLeft(2, '0')}';
          
          return MatchTile(
            homeTeam: match.homeTeam.name,
            awayTeam: match.awayTeam.name,
            kickoff: match.isLive ? 'LIVE' : (match.isFinished ? 'Vége' : timeStr),
            isLive: match.isLive,
            aiScore: match.aiScore,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MatchDetailScreen(match: match),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
