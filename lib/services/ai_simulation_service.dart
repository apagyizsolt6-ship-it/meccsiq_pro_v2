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

  // Új mezők
  final double over25Probability;
  final double under25Probability;
  final double bttsYesProbability;
  final double bttsNoProbability;
  final String dataQuality; // 'strong' | 'medium' | 'weak'
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
    this.over25Probability = 0,
    this.under25Probability = 0,
    this.bttsYesProbability = 0,
    this.bttsNoProbability = 0,
    this.dataQuality = 'weak',
    this.usedWeightedH2h = false,
  });
}

class AiSimulationService {
  static final StatpalService _statpalService = StatpalService();
  static final Random _random = Random();

  /// Liga-specifikus hazai előny (gól)
  static double _homeAdvantageForLeague(String? leagueId) {
    if (leagueId == null) return 0.15;
    switch (leagueId) {
      case '3037': // Premier League
        return 0.22;
      case '3062': // Bundesliga
        return 0.20;
      case '3102': // Serie A
        return 0.18;
      case '3232': // La Liga
        return 0.18;
      case '3054': // Ligue 1
        return 0.17;
      case '3081': // NB I
        return 0.16;
      case '2838': // Champions League
      case '2840': // Europa League
      case '20686': // Conference
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
    bool usedWeightedH2h = false;

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

    // ========== 2. H2H (súlyozott) ==========
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

            // Újabb meccsek nagyobb súllyal (index 0 = legújabb)
            for (int i = 0; i < matches.length; i++) {
              final m = matches[i];
              if (m is! Map) continue;

              final t1Id = m['team1_id']?.toString();
              final t2Id = m['team2_id']?.toString();
              final t1Score =
                  double.tryParse(m['team1_score']?.toString() ?? '') ?? 0;
              final t2Score =
                  double.tryParse(m['team2_score']?.toString() ?? '') ?? 0;

              // Súly: legújabb 5 → 2.0, 6–15 → 1.3, többi → 1.0
              double w = 1.0;
              if (i < 5) {
                w = 2.0;
              } else if (i < 15) {
                w = 1.3;
              }

              final t1Goals = t1Score.toInt().toString();
              final t2Goals = t2Score.toInt().toString();

              if (t1Id == team1Id) {
                homeGoalsWeighted += t1Score * w;
                awayGoalsWeighted += t2Score * w;
                weightSum += w;
                if (counted < 6) {
                  recentScores.add(t1Goals + '-' + t2Goals);
                }
              } else if (t2Id == team1Id) {
                homeGoalsWeighted += t2Score * w;
                awayGoalsWeighted += t1Score * w;
                weightSum += w;
                if (counted < 6) {
                  recentScores.add(t2Goals + '-' + t1Goals);
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

    // ========== 3. KOMBINÁLÁS ==========
    // Ha kevés H2H (< 5), a tabella nagyobb súlyt kap
    final bool weakH2h = h2hCount < 5;
    final double h2hWeight = weakH2h ? 0.25 : 0.55;
    final double tableWeight = 1.0 - h2hWeight;

    if (homeScoredAvg != null && awayConcededAvg != null) {
      final combinedHome = (homeScoredAvg + awayConcededAvg) / 2;
      if (h2hCount > 0) {
        homeAvg = (homeAvg * h2hWeight) + (combinedHome * tableWeight);
      } else {
        homeAvg = combinedHome;
      }
    }

    if (awayScoredAvg != null && homeConcededAvg != null) {
      final combinedAway = (awayScoredAvg + homeConcededAvg) / 2;
      if (h2hCount > 0) {
        awayAvg = (awayAvg * h2hWeight) + (combinedAway * tableWeight);
      } else {
        awayAvg = combinedAway;
      }
    }

    // Forma
    homeAvg *= _formMultiplier(homeForm);
    awayAvg *= _formMultiplier(awayForm);

    // Liga-specifikus hazai előny
    homeAvg += _homeAdvantageForLeague(leagueId);

    homeAvg = homeAvg.clamp(0.35, 3.4);
    awayAvg = awayAvg.clamp(0.25, 3.0);

    // Adatminőség
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

    // ========== 4. POISSON MONTE CARLO ==========
    const int totalSims = 50000;
    int homeWins = 0;
    int draws = 0;
    int awayWins = 0;
    int over25 = 0;
    int bttsYes = 0;
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

      if (hg + ag >= 3) over25++;
      if (hg > 0 && ag > 0) bttsYes++;

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
      over25Probability: (over25 / totalSims) * 100,
      under25Probability: ((totalSims - over25) / totalSims) * 100,
      bttsYesProbability: (bttsYes / totalSims) * 100,
      bttsNoProbability: ((totalSims - bttsYes) / totalSims) * 100,
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

    final homePct = s.homeWinProbability.toStringAsFixed(1);
    final drawPct = s.drawProbability.toStringAsFixed(1);
    final awayPct = s.awayWinProbability.toStringAsFixed(1);
    final homeXg = s.averageHomeGoals.toString();
    final awayXg = s.averageAwayGoals.toString();
    final overPct = s.over25Probability.toStringAsFixed(1);
    final bttsPct = s.bttsYesProbability.toStringAsFixed(1);

    String qualityText;
    if (s.dataQuality == 'strong') {
      qualityText = 'Erős adatminőség (sok H2H + tabella).';
    } else if (s.dataQuality == 'medium') {
      qualityText = 'Közepes adatminőség.';
    } else {
      qualityText =
          'Gyenge adatminőség – kevés H2H, óvatosan kezeld az esélyeket.';
    }

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

    buffer.write('Over 2.5: **');
    buffer.write(overPct);
    buffer.write('%**  |  BTTS igen: **');
    buffer.write(bttsPct);
    buffer.write('%**\n\n');

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
      buffer.write(' egymás elleni meccs');
      if (s.usedWeightedH2h) {
        buffer.write(' (súlyozott: újabb meccsek nagyobb súllyal)');
      }
      buffer.write('\n');
      if (s.recentScores.isNotEmpty) {
        buffer.write('Utolsó eredmények: ');
        buffer.write(s.recentScores.join('  •  '));
        buffer.write('\n');
      }
    } else {
      buffer.write(
          '\nH2H adat nem volt elérhető, a tabella és a forma alapján számoltunk.\n');
    }

    buffer.write('\n');
    buffer.write(qualityText);
    buffer.write(
        '\n\nA modell súlyozott H2H + tabella + forma + liga-specifikus hazai előnyt kombinál, majd Poisson-eloszlással szimulál.');

    return buffer.toString();
  }
}
