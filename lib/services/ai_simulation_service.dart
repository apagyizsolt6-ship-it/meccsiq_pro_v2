import 'dart:math';
import 'statpal_service.dart';

class MatchSimulationResult {
  final int totalSimulations;
  final double homeWinProbability;
  final double drawProbability;
  final double awayWinProbability;
  final String mostLikelyScore;
  final double averageHomeGoals;
  final double averageAwayGoals;
  final int h2hMatchesUsed;
  final List<String> recentScores;
  final String? homeForm;
  final String? awayForm;
  final int? homePosition;
  final int? awayPosition;
  final double? homeGoalsScoredAvg;
  final double? homeGoalsConcededAvg;
  final double? awayGoalsScoredAvg;
  final double? awayGoalsConcededAvg;

  MatchSimulationResult({
    required this.totalSimulations,
    required this.homeWinProbability,
    required this.drawProbability,
    required this.awayWinProbability,
    required this.mostLikelyScore,
    required this.averageHomeGoals,
    required this.averageAwayGoals,
    this.h2hMatchesUsed = 0,
    this.recentScores = const [],
    this.homeForm,
    this.awayForm,
    this.homePosition,
    this.awayPosition,
    this.homeGoalsScoredAvg,
    this.homeGoalsConcededAvg,
    this.awayGoalsScoredAvg,
    this.awayGoalsConcededAvg,
  });
}

class AiSimulationService {
  static final StatpalService _statpalService = StatpalService();
  static final Random _random = Random();

  static int _poisson(double lambda) {
    if (lambda <= 0) return 0;
    final L = exp(-lambda);
    int k = 0;
    double p = 1.0;
    do {
      k++;
      p *= _random.nextDouble();
    } while (p > L);
    return k - 1;
  }

  static double _formMultiplier(String? form) {
    if (form == null || form.isEmpty) return 1.0;
    double score = 0;
    int count = 0;
    for (final c in form.toUpperCase().split('')) {
      if (c == 'W') {
        score += 1.15;
        count++;
      } else if (c == 'D') {
        score += 1.0;
        count++;
      } else if (c == 'L') {
        score += 0.85;
        count++;
      }
    }
    return count > 0 ? score / count : 1.0;
  }

  static Future<MatchSimulationResult> runMonteCarloSimulation({
    required String homeTeam,
    required String awayTeam,
    String? team1Id,
    String? team2Id,
    String? leagueId,
  }) async {
    double homeAvg = 1.35;
    double awayAvg = 1.10;
    int h2hCount = 0;
    List<String> recentScores = [];

    String? homeForm;
    String? awayForm;
    int? homePos;
    int? awayPos;
    double? homeScoredAvg;
    double? homeConcededAvg;
    double? awayScoredAvg;
    double? awayConcededAvg;

    // ========== 1. TABELLA ==========
    if (leagueId != null && leagueId.isNotEmpty) {
      try {
        final standingsData = await _statpalService.getStandings(leagueId);
        if (standingsData != null && standingsData['standings'] != null) {
          final tournaments = standingsData['standings']['tournament'];
          if (tournaments is List) {
            for (final t in tournaments) {
              final teams = t['team'];
              if (teams is! List) continue;

              for (final team in teams) {
                if (team is! Map) continue;
                final id = team['id']?.toString();

                if (id == team1Id) {
                  homeForm = team['recent_form']?.toString();
                  homePos = int.tryParse(team['position']?.toString() ?? '');

                  final homeStats = team['home'];
                  if (homeStats is Map) {
                    final gp = double.tryParse(
                            homeStats['games_played']?.toString() ?? '0') ??
                        0;
                    final gs = double.tryParse(
                            homeStats['goals_scored']?.toString() ?? '0') ??
                        0;
                    final ga = double.tryParse(
                            homeStats['goals_allowed']?.toString() ?? '0') ??
                        0;
                    if (gp > 0) {
                      homeScoredAvg = gs / gp;
                      homeConcededAvg = ga / gp;
                    }
                  }
                }

                if (id == team2Id) {
                  awayForm = team['recent_form']?.toString();
                  awayPos = int.tryParse(team['position']?.toString() ?? '');

                  final awayStats = team['away'];
                  if (awayStats is Map) {
                    final gp = double.tryParse(
                            awayStats['games_played']?.toString() ?? '0') ??
                        0;
                    final gs = double.tryParse(
                            awayStats['goals_scored']?.toString() ?? '0') ??
                        0;
                    final ga = double.tryParse(
                            awayStats['goals_allowed']?.toString() ?? '0') ??
                        0;
                    if (gp > 0) {
                      awayScoredAvg = gs / gp;
                      awayConcededAvg = ga / gp;
                    }
                  }
                }
              }
            }
          }
        }
      } catch (_) {}
    }

    // ========== 2. H2H ==========
    if (team1Id != null &&
        team2Id != null &&
        team1Id.isNotEmpty &&
        team2Id.isNotEmpty) {
      try {
        final h2hData =
            await _statpalService.getHeadToHeadStats(team1Id, team2Id);
        if (h2hData != null && h2hData['head-to-head'] != null) {
          final recent = h2hData['head-to-head']['recent_meetings'];
          dynamic rawMatches = recent?['match'];

          List<dynamic> matches = [];
          if (rawMatches is List) {
            matches = rawMatches;
          } else if (rawMatches is Map) {
            matches = [rawMatches];
          }

          if (matches.isNotEmpty) {
            double homeGoalsSum = 0;
            double awayGoalsSum = 0;
            int counted = 0;

            for (final m in matches) {
              if (m is! Map) continue;

              final t1Id = m['team1_id']?.toString();
              final t2Id = m['team2_id']?.toString();
              final t1Score =
                  double.tryParse(m['team1_score']?.toString() ?? '') ?? 0;
              final t2Score =
                  double.tryParse(m['team2_score']?.toString() ?? '') ?? 0;

              final t1Goals = t1Score.toInt().toString();
              final t2Goals = t2Score.toInt().toString();

              if (t1Id == team1Id) {
                homeGoalsSum += t1Score;
                awayGoalsSum += t2Score;
                recentScores.add(t1Goals + '-' + t2Goals);
              } else if (t2Id == team1Id) {
                homeGoalsSum += t2Score;
                awayGoalsSum += t1Score;
                recentScores.add(t2Goals + '-' + t1Goals);
              } else {
                continue;
              }
              counted++;
            }

            if (counted > 0) {
              homeAvg = homeGoalsSum / counted;
              awayAvg = awayGoalsSum / counted;
              h2hCount = counted;
            }
          }
        }
      } catch (_) {}
    }

    // ========== 3. KOMBINÁLÁS ==========
    if (homeScoredAvg != null && awayConcededAvg != null) {
      final combinedHome = (homeScoredAvg + awayConcededAvg) / 2;
      if (h2hCount > 0) {
        homeAvg = (homeAvg * 0.55) + (combinedHome * 0.45);
      } else {
        homeAvg = combinedHome;
      }
    }

    if (awayScoredAvg != null && homeConcededAvg != null) {
      final combinedAway = (awayScoredAvg + homeConcededAvg) / 2;
      if (h2hCount > 0) {
        awayAvg = (awayAvg * 0.55) + (combinedAway * 0.45);
      } else {
        awayAvg = combinedAway;
      }
    }

    homeAvg *= _formMultiplier(homeForm);
    awayAvg *= _formMultiplier(awayForm);
    homeAvg += 0.15;

    homeAvg = homeAvg.clamp(0.4, 3.2);
    awayAvg = awayAvg.clamp(0.3, 2.8);

    // ========== 4. POISSON ==========
    const int totalSims = 50000;
    int homeWins = 0;
    int draws = 0;
    int awayWins = 0;
    final Map<String, int> scoreCounts = {};

    for (int i = 0; i < totalSims; i++) {
      final hg = _poisson(homeAvg);
      final ag = _poisson(awayAvg);

      if (hg > ag) {
        homeWins++;
      } else if (hg == ag) {
        draws++;
      } else {
        awayWins++;
      }

      final key = hg.toString() + ':' + ag.toString();
      scoreCounts[key] = (scoreCounts[key] ?? 0) + 1;
    }

    String mostLikely = '1:1';
    int maxCount = -1;
    scoreCounts.forEach((score, count) {
      if (count > maxCount) {
        maxCount = count;
        mostLikely = score;
      }
    });

    return MatchSimulationResult(
      totalSimulations: totalSims,
      homeWinProbability: (homeWins / totalSims) * 100,
      drawProbability: (draws / totalSims) * 100,
      awayWinProbability: (awayWins / totalSims) * 100,
      mostLikelyScore: mostLikely,
      averageHomeGoals: double.parse(homeAvg.toStringAsFixed(2)),
      averageAwayGoals: double.parse(awayAvg.toStringAsFixed(2)),
      h2hMatchesUsed: h2hCount,
      recentScores: recentScores.take(6).toList(),
      homeForm: homeForm,
      awayForm: awayForm,
      homePosition: homePos,
      awayPosition: awayPos,
      homeGoalsScoredAvg: homeScoredAvg,
      homeGoalsConcededAvg: homeConcededAvg,
      awayGoalsScoredAvg: awayScoredAvg,
      awayGoalsConcededAvg: awayConcededAvg,
    );
  }

  static Future<String> getAiMatchAnalysis({
    required String homeTeam,
    required String awayTeam,
    required MatchSimulationResult simulation,
  }) async {
    final s = simulation;

    final favorite =
        s.homeWinProbability >= s.awayWinProbability ? homeTeam : awayTeam;
    final diff = (s.homeWinProbability - s.awayWinProbability).abs();

    String strength;
    if (diff > 25) {
      strength = 'egyértelmű esélyes';
    } else if (diff > 12) {
      strength = 'enyhe esélyes';
    } else {
      strength = 'szoros, kiegyenlített meccs';
    }

    final homePct = s.homeWinProbability.toStringAsFixed(1);
    final drawPct = s.drawProbability.toStringAsFixed(1);
    final awayPct = s.awayWinProbability.toStringAsFixed(1);
    final homeXg = s.averageHomeGoals.toString();
    final awayXg = s.averageAwayGoals.toString();

    final buffer = StringBuffer();

    buffer.write('**[Valós StatPal adatmodell – Poisson Monte Carlo]**\n\n');
    buffer.write('50 000 szimuláció alapján a mérkőzés ');
    buffer.write(strength);
    buffer.write(': **');
    buffer.write(favorite);
    buffer.write('**.\n\n');

    buffer.write('• Hazai győzelem (');
    buffer.write(homeTeam);
    buffer.write('): **');
    buffer.write(homePct);
    buffer.write('%**\n');

    buffer.write('• Döntetlen: **');
    buffer.write(drawPct);
    buffer.write('%**\n');

    buffer.write('• Vendég győzelem (');
    buffer.write(awayTeam);
    buffer.write('): **');
    buffer.write(awayPct);
    buffer.write('%**\n\n');

    buffer.write('Várható gólátlag (xG): **');
    buffer.write(homeXg);
    buffer.write(' – ');
    buffer.write(awayXg);
    buffer.write('**\n');

    buffer.write('Legvalószínűbb eredmény: **');
    buffer.write(s.mostLikelyScore);
    buffer.write('**\n\n');

    if (s.homePosition != null || s.awayPosition != null) {
      buffer.write('Tabella helyzet: ');
      buffer.write(s.homePosition?.toString() ?? '?');
      buffer.write(' – ');
      buffer.write(s.awayPosition?.toString() ?? '?');
      buffer.write('\n');
    }

    if (s.homeForm != null || s.awayForm != null) {
      buffer.write('Forma (utolsó 5): ');
      buffer.write(s.homeForm ?? '–');
      buffer.write(' | ');
      buffer.write(s.awayForm ?? '–');
      buffer.write('\n');
    }

    if (s.homeGoalsScoredAvg != null) {
      buffer.write('Hazai gólátlag (hazai meccseken): ');
      buffer.write(s.homeGoalsScoredAvg!.toStringAsFixed(2));
      buffer.write(' rúgott / ');
      buffer.write(s.homeGoalsConcededAvg?.toStringAsFixed(2) ?? '?');
      buffer.write(' kapott\n');
    }

    if (s.awayGoalsScoredAvg != null) {
      buffer.write('Vendég gólátlag (idegenben): ');
      buffer.write(s.awayGoalsScoredAvg!.toStringAsFixed(2));
      buffer.write(' rúgott / ');
      buffer.write(s.awayGoalsConcededAvg?.toStringAsFixed(2) ?? '?');
      buffer.write(' kapott\n');
    }

    if (s.h2hMatchesUsed > 0) {
      buffer.write('\nH2H alap: ');
      buffer.write(s.h2hMatchesUsed.toString());
      buffer.write(' egymás elleni meccs\n');
      if (s.recentScores.isNotEmpty) {
        buffer.write('Utolsó eredmények: ');
        buffer.write(s.recentScores.join('  •  '));
        buffer.write('\n');
      }
    } else {
      buffer.write(
          '\nH2H adat nem volt elérhető, a tabella és a forma alapján számoltunk.\n');
    }

    buffer.write(
        '\nA modell a StatPal H2H + tabella (hazai/vendég gólátlag) + forma (WDWWL) adatait kombinálja, majd Poisson-eloszlással szimulálja a gólokat.');

    return buffer.toString();
  }
}
