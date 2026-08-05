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

  // Gólpiacok
  final double over15Probability;
  final double under15Probability;
  final double over25Probability;
  final double under25Probability;
  final double over35Probability;
  final double under35Probability;

  // BTTS
  final double bttsYesProbability;
  final double bttsNoProbability;

  // Double Chance
  final double doubleChance1X;
  final double doubleChance12;
  final double doubleChanceX2;

  // Top 5 pontos eredmény
  final List<Map<String, dynamic>> topScores;

  final String dataQuality;
  final bool usedWeightedH2h;

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
    this.over15Probability = 0,
    this.under15Probability = 0,
    this.over25Probability = 0,
    this.under25Probability = 0,
    this.over35Probability = 0,
    this.under35Probability = 0,
    this.bttsYesProbability = 0,
    this.bttsNoProbability = 0,
    this.doubleChance1X = 0,
    this.doubleChance12 = 0,
    this.doubleChanceX2 = 0,
    this.topScores = const [],
    this.dataQuality = 'weak',
    this.usedWeightedH2h = false,
  });
}

class AiSimulationService {
  static final StatpalService _statpalService = StatpalService();
  static final Random _random = Random();

  static double _homeAdvantageForLeague(String? leagueId) {
    if (leagueId == null) return 0.15;
    switch (leagueId) {
      case '3037':
        return 0.22;
      case '3062':
        return 0.20;
      case '3102':
        return 0.18;
      case '3232':
        return 0.18;
      case '3054':
        return 0.17;
      case '3081':
        return 0.16;
      case '2838':
      case '2840':
      case '20686':
        return 0.12;
      default:
        return 0.15;
    }
  }

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
        score += 1.18;
        count++;
      } else if (c == 'D') {
        score += 1.0;
        count++;
      } else if (c == 'L') {
        score += 0.82;
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
    bool usedWeightedH2h = false;

    String? homeForm;
    String? awayForm;
    int? homePos;
    int? awayPos;
    double? homeScoredAvg;
    double? homeConcededAvg;
    double? awayScoredAvg;
    double? awayConcededAvg;

    // 1. TABELLA
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

    // 2. H2H (súlyozott)
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
            double homeGoalsWeighted = 0;
            double awayGoalsWeighted = 0;
            double weightSum = 0;
            int counted = 0;

            for (int i = 0; i < matches.length; i++) {
              final m = matches[i];
              if (m is! Map) continue;

              final t1Id = m['team1_id']?.toString();
              final t2Id = m['team2_id']?.toString();
              final t1Score =
                  double.tryParse(m['team1_score']?.toString() ?? '') ?? 0;
              final t2Score =
                  double.tryParse(m['team2_score']?.toString() ?? '') ?? 0;

              double w = 1.0;
              if (i < 5) {
                w = 2.2;
              } else if (i < 12) {
                w = 1.4;
              }

              if (t1Id == team1Id) {
                homeGoalsWeighted += t1Score * w;
                awayGoalsWeighted += t2Score * w;
                weightSum += w;
                if (counted < 6) {
                  recentScores.add(
                      '${t1Score.toInt()}-${t2Score.toInt()}');
                }
              } else if (t2Id == team1Id) {
                homeGoalsWeighted += t2Score * w;
                awayGoalsWeighted += t1Score * w;
                weightSum += w;
                if (counted < 6) {
                  recentScores.add(
                      '${t2Score.toInt()}-${t1Score.toInt()}');
                }
              } else {
                continue;
              }
              counted++;
            }

            if (counted > 0 && weightSum > 0) {
              homeAvg = homeGoalsWeighted / weightSum;
              awayAvg = awayGoalsWeighted / weightSum;
              h2hCount = counted;
              usedWeightedH2h = true;
            }
          }
        }
      } catch (_) {}
    }

    // 3. KOMBINÁLÁS
    final bool weakH2h = h2hCount < 6;
    final double h2hWeight = weakH2h ? 0.22 : 0.58;
    final double tableWeight = 1.0 - h2hWeight;

    if (homeScoredAvg != null && awayConcededAvg != null) {
      final combinedHome = (homeScoredAvg * 0.55) + (awayConcededAvg * 0.45);
      if (h2hCount > 0) {
        homeAvg = (homeAvg * h2hWeight) + (combinedHome * tableWeight);
      } else {
        homeAvg = combinedHome;
      }
    }

    if (awayScoredAvg != null && homeConcededAvg != null) {
      final combinedAway = (awayScoredAvg * 0.55) + (homeConcededAvg * 0.45);
      if (h2hCount > 0) {
        awayAvg = (awayAvg * h2hWeight) + (combinedAway * tableWeight);
      } else {
        awayAvg = combinedAway;
      }
    }

    homeAvg *= _formMultiplier(homeForm);
    awayAvg *= _formMultiplier(awayForm);
    homeAvg += _homeAdvantageForLeague(leagueId);

    homeAvg = homeAvg.clamp(0.30, 3.5);
    awayAvg = awayAvg.clamp(0.22, 3.1);

    String dataQuality;
    if (h2hCount >= 10 &&
        homeScoredAvg != null &&
        awayScoredAvg != null) {
      dataQuality = 'strong';
    } else if (h2hCount >= 5 ||
        (homeScoredAvg != null && awayScoredAvg != null)) {
      dataQuality = 'medium';
    } else {
      dataQuality = 'weak';
    }

    // 4. MONTE CARLO
    const int totalSims = 50000;
    int homeWins = 0;
    int draws = 0;
    int awayWins = 0;
    int over15 = 0;
    int over25 = 0;
    int over35 = 0;
    int bttsYes = 0;
    final Map<String, int> scoreCounts = {};

    for (int i = 0; i < totalSims; i++) {
      final hg = _poisson(homeAvg);
      final ag = _poisson(awayAvg);
      final totalGoals = hg + ag;

      if (hg > ag) {
        homeWins++;
      } else if (hg == ag) {
        draws++;
      } else {
        awayWins++;
      }

      if (totalGoals >= 2) over15++;
      if (totalGoals >= 3) over25++;
      if (totalGoals >= 4) over35++;
      if (hg > 0 && ag > 0) bttsYes++;

      final key = '$hg:$ag';
      scoreCounts[key] = (scoreCounts[key] ?? 0) + 1;
    }

    final sortedScores = scoreCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topScores = sortedScores.take(5).map((e) {
      return {
        'score': e.key,
        'probability': (e.value / totalSims) * 100,
      };
    }).toList();

    final mostLikely =
        topScores.isNotEmpty ? topScores.first['score'] as String : '1:1';

    final homeWinPct = (homeWins / totalSims) * 100;
    final drawPct = (draws / totalSims) * 100;
    final awayWinPct = (awayWins / totalSims) * 100;

    return MatchSimulationResult(
      totalSimulations: totalSims,
      homeWinProbability: homeWinPct,
      drawProbability: drawPct,
      awayWinProbability: awayWinPct,
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
      over15Probability: (over15 / totalSims) * 100,
      under15Probability: ((totalSims - over15) / totalSims) * 100,
      over25Probability: (over25 / totalSims) * 100,
      under25Probability: ((totalSims - over25) / totalSims) * 100,
      over35Probability: (over35 / totalSims) * 100,
      under35Probability: ((totalSims - over35) / totalSims) * 100,
      bttsYesProbability: (bttsYes / totalSims) * 100,
      bttsNoProbability: ((totalSims - bttsYes) / totalSims) * 100,
      doubleChance1X: homeWinPct + drawPct,
      doubleChance12: homeWinPct + awayWinPct,
      doubleChanceX2: drawPct + awayWinPct,
      topScores: topScores,
      dataQuality: dataQuality,
      usedWeightedH2h: usedWeightedH2h,
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
        '• Hazai győzelem ($homeTeam): **${s.homeWinProbability.toStringAsFixed(1)}%**');
    buffer.writeln(
        '• Döntetlen: **${s.drawProbability.toStringAsFixed(1)}%**');
    buffer.writeln(
        '• Vendég győzelem ($awayTeam): **${s.awayWinProbability.toStringAsFixed(1)}%**\n');

    buffer.writeln(
        'Várható gólátlag (xG): **${s.averageHomeGoals} – ${s.averageAwayGoals}**');
    buffer.writeln('Legvalószínűbb eredmény: **${s.mostLikelyScore}**\n');

    buffer.writeln(
        'Over 2.5: **${s.over25Probability.toStringAsFixed(1)}%**  |  BTTS igen: **${s.bttsYesProbability.toStringAsFixed(1)}%**\n');

    if (s.homePosition != null || s.awayPosition != null) {
      buffer.writeln(
          'Tabella helyzet: ${s.homePosition ?? "?"} – ${s.awayPosition ?? "?"}');
    }

    if (s.homeForm != null || s.awayForm != null) {
      buffer.writeln(
          'Forma (utolsó 5): ${s.homeForm ?? "–"} | ${s.awayForm ?? "–"}');
    }

    if (s.h2hMatchesUsed > 0) {
      buffer.write('\nH2H alap: ${s.h2hMatchesUsed} egymás elleni meccs');
      if (s.usedWeightedH2h) {
        buffer.write(' (súlyozott)');
      }
      buffer.writeln();
      if (s.recentScores.isNotEmpty) {
        buffer.writeln('Utolsó eredmények: ${s.recentScores.join("  •  ")}');
      }
    }

    buffer.writeln();
    if (s.dataQuality == 'strong') {
      buffer.writeln('Erős adatminőség (sok H2H + tabella).');
    } else if (s.dataQuality == 'medium') {
      buffer.writeln('Közepes adatminőség.');
    } else {
      buffer.writeln(
          'Gyenge adatminőség – kevés H2H, óvatosan kezeld az esélyeket.');
    }

    return buffer.toString();
  }
}
