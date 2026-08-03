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

    // ========== 1. TABELLA (Standings) ==========
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

              if (t1Id == team1Id) {
                homeGoalsSum += t1Score;
                awayGoalsSum += t2Score;
                recentScores.add('\( {t1Score.toInt()}- \){t2Score.toInt()}');
              } else if (t2Id == team1Id) {
                homeGoalsSum += t2Score;
                awayGoalsSum += t1Score;
                recentScores.add('\( {t2Score.toInt()}- \){t1Score.toInt()}');
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

    // Forma
    homeAvg *= _formMultiplier(homeForm);
    awayAvg *= _formMultiplier(awayForm);

    // Hazai pálya előny
    homeAvg += 0.15;

    homeAvg = homeAvg.clamp(0.4, 3.2);
    awayAvg = awayAvg.clamp(0.3, 2.8);

    // ========== 4. POISSON MONTE CARLO ==========
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

      final key = '$hg:$ag';
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

    final buffer = StringBuffer();

    buffer.writeln('**[Valós StatPal adatmodell – Poisson Monte Carlo]**\n');
    buffer.writeln(
        '50 000 szimuláció alapján a mérkőzés $strength: **$favorite**.\n');
    buffer.writeln(
        '• Hazai győzelem (\( homeTeam): ** \){s.homeWinProbability.toStringAsFixed(1)}%**');
    buffer.writeln(
        '• Döntetlen: **${s.drawProbability.toStringAsFixed(1)}%**');
    buffer.writeln(
        '• Vendég győzelem (\( awayTeam): ** \){s.awayWinProbability.toStringAsFixed(1)}%**\n');
    buffer.writeln(
        'Várható gólátlag (xG): **${s.averageHomeGoals} – ${s.averageAwayGoals}**');
    buffer.writeln('Legvalószínűbb eredmény: **${s.mostLikelyScore}**\n');

    if (s.homePosition != null || s.awayPosition != null) {
      buffer.writeln(
          'Tabella helyzet: ${s.homePosition ?? "?"} – ${s.awayPosition ?? "?"}');
    }

    if (s.homeForm != null || s.awayForm != null) {
      buffer.writeln(
          'Forma (utolsó 5): ${s.homeForm ?? "–"} | ${s.awayForm ?? "–"}');
    }

    if (s.homeGoalsScoredAvg != null) {
      buffer.writeln(
          'Hazai gólátlag (hazai meccseken): ${s.homeGoalsScoredAvg!.toStringAsFixed(2)} rúgott / ${s.homeGoalsConcededAvg?.toStringAsFixed(2) ?? "?"} kapott');
    }

    if (s.awayGoalsScoredAvg != null) {
      buffer.writeln(
          'Vendég gólátlag (idegenben): ${s.awayGoalsScoredAvg!.toStringAsFixed(2)} rúgott / ${s.awayGoalsConcededAvg?.toStringAsFixed(2) ?? "?"} kapott');
    }

    if (s.h2hMatchesUsed > 0) {
      buffer.writeln('\nH2H alap: ${s.h2hMatchesUsed} egymás elleni meccs');
      if (s.recentScores.isNotEmpty) {
        buffer.writeln('Utolsó eredmények: ${s.recentScores.join("  •  ")}');
      }
    } else {
      buffer.writeln(
          '\nH2H adat nem volt elérhető, a tabella és a forma alapján számoltunk.');
    }

    buffer.writeln(
        '\nA modell a StatPal H2H + tabella (hazai/vendég gólátlag) + forma (WDWWL) adatait kombinálja, majd Poisson-eloszlással szimulálja a gólokat.');

    return buffer.toString();
  }
}
