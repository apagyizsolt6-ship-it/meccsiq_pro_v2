import 'package:flutter/material.dart';
import '../../models/match_model.dart';
import '../../models/league_model.dart';
import '../../models/team_model.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Teszt adatok a meglévő modellekkel
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
      appBar: AppBar(
        title: const Text('Meccsek'),
      ),
      body: ListView.builder(
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final match = matches[index];
          return ListTile(
            leading: Text(
              match.isLive ? 'LIVE' : (match.isFinished ? 'Vége' : '21:00'),
              style: TextStyle(
                color: match.isLive ? Colors.red : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            title: Text('${match.homeTeam.name} - ${match.awayTeam.name}'),
            trailing: match.hasScore
                ? Text('${match.homeScore} : ${match.awayScore}',
                    style: const TextStyle(fontWeight: FontWeight.bold))
                : null,
          );
        },
      ),
    );
  }
}
