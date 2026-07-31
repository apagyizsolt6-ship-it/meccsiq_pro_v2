/*
===========================================
MeccsIQ Pro v2.0
Build: #004
Version: v2.0.0
File: matches_screen.dart
===========================================
*/

import 'package:flutter/material.dart';

import 'widgets/day_selector.dart';
import 'widgets/filter_bar.dart';
import 'widgets/league_header.dart';
import 'widgets/match_tile.dart';
import 'widgets/search_bar.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  bool _premierExpanded = true;
  bool _laligaExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meccsek',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [

          const SizedBox(height: 12),

          const MatchSearchBar(),

          const SizedBox(height: 12),

          const DaySelector(),

          const SizedBox(height: 12),

          const FilterBar(),

          const SizedBox(height: 16),

          LeagueHeader(
            leagueName: "Premier League",
            country: "Anglia",
            matchCount: 3,
            expanded: _premierExpanded,
            onTap: () {
              setState(() {
                _premierExpanded = !_premierExpanded;
              });
            },
          ),

          if (_premierExpanded) ...[
            const MatchTile(
              homeTeam: "Liverpool",
              awayTeam: "Arsenal",
              kickoff: "18:30",
              aiScore: 94,
            ),
            const MatchTile(
              homeTeam: "Chelsea",
              awayTeam: "Manchester City",
              kickoff: "21:00",
              aiScore: 89,
              isLive: true,
            ),
            const MatchTile(
              homeTeam: "Tottenham",
              awayTeam: "Newcastle",
              kickoff: "16:00",
              aiScore: 81,
            ),
          ],

          const SizedBox(height: 8),

          LeagueHeader(
            leagueName: "LaLiga",
            country: "Spanyolország",
            matchCount: 2,
            expanded: _laligaExpanded,
            onTap: () {
              setState(() {
                _laligaExpanded = !_laligaExpanded;
              });
            },
          ),

          if (_laligaExpanded) ...[
            const MatchTile(
              homeTeam: "Barcelona",
              awayTeam: "Sevilla",
              kickoff: "19:00",
              aiScore: 91,
            ),
            const MatchTile(
              homeTeam: "Real Madrid",
              awayTeam: "Valencia",
              kickoff: "21:30",
              aiScore: 96,
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
