/*
===========================================
MeccsIQ Pro v2.0
Build: #006
Version: v2.0.0
File: match_model.dart
===========================================
*/

import 'league_model.dart';
import 'team_model.dart';

class MatchModel {
  const MatchModel({
    required this.id,
    required this.league,
    required this.homeTeam,
    required this.awayTeam,
    required this.kickoff,

    this.homeScore,
    this.awayScore,

    this.status = MatchStatus.notStarted,

    this.aiScore,

    this.homeOdd,
    this.drawOdd,
    this.awayOdd,

    this.isFavorite = false,
    this.isValueBet = false,
  });

  final int id;

  final LeagueModel league;

  final TeamModel homeTeam;
  final TeamModel awayTeam;

  final DateTime kickoff;

  final int? homeScore;
  final int? awayScore;

  final MatchStatus status;

  final int? aiScore;

  final double? homeOdd;
  final double? drawOdd;
  final double? awayOdd;

  final bool isFavorite;

  final bool isValueBet;

  bool get isLive => status == MatchStatus.live;

  bool get isFinished => status == MatchStatus.finished;

  bool get hasScore =>
      homeScore != null && awayScore != null;

  MatchModel copyWith({
    int? id,
    LeagueModel? league,
    TeamModel? homeTeam,
    TeamModel? awayTeam,
    DateTime? kickoff,
    int? homeScore,
    int? awayScore,
    MatchStatus? status,
    int? aiScore,
    double? homeOdd,
    double? drawOdd,
    double? awayOdd,
    bool? isFavorite,
    bool? isValueBet,
  }) {
    return MatchModel(
      id: id ?? this.id,
      league: league ?? this.league,
      homeTeam: homeTeam ?? this.homeTeam,
      awayTeam: awayTeam ?? this.awayTeam,
      kickoff: kickoff ?? this.kickoff,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      status: status ?? this.status,
      aiScore: aiScore ?? this.aiScore,
      homeOdd: homeOdd ?? this.homeOdd,
      drawOdd: drawOdd ?? this.drawOdd,
      awayOdd: awayOdd ?? this.awayOdd,
      isFavorite: isFavorite ?? this.isFavorite,
      isValueBet: isValueBet ?? this.isValueBet,
    );
  }
}

enum MatchStatus {
  notStarted,
  live,
  halftime,
  finished,
  postponed,
  cancelled,
}
