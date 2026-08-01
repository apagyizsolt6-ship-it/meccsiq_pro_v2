import 'package:flutter/material.dart';
import '../../models/match_model.dart';
import '../../models/league_model.dart';
import '../../models/team_model.dart';
import 'widgets/match_tile.dart';
import 'widgets/league_header.dart';
import 'widgets/day_selector.dart';
import 'widgets/filter_bar.dart';
import 'widgets/search_bar.dart' as custom_search;

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({Key? key}) : super(key: key);

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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Meccsek', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          const custom_search.SearchBar(),
          const DaySelector(),
          const FilterBar(),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final match = matches[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (index == 0)
                      const LeagueHeader(),
                    MatchTile(match: match),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
