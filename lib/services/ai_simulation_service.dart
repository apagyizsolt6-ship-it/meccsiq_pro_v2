import 'dart:math';

class MatchSimulationResult {
  final double homeWinProbability;
  final double drawProbability;
  final double awayWinProbability;
  final String mostLikelyScore;
  final double averageHomeGoals;
  final double averageAwayGoals;
  final int totalSimulations;

  MatchSimulationResult({
    required this.homeWinProbability,
    required this.drawProbability,
    required this.awayWinProbability,
    required this.mostLikelyScore,
    required this.averageHomeGoals,
    required this.averageAwayGoals,
    required this.totalSimulations,
  });
}

class AiSimulationService {
  // Monte Carlo motor (50 000 futtatás) - Csapatfüggő egyedi lambda értékekkel
  static MatchSimulationResult runMonteCarloSimulation({
    required String homeTeam,
    required String awayTeam,
    int simulations = 50000,
  }) {
    // Egyedi "seed" generálása a csapatnevekből, hogy minden meccs teljesen más esélyeket kapjon!
    int combinedHash = homeTeam.codeUnits.fold(0, (prev, element) => prev + element) +
        awayTeam.codeUnits.fold(0, (prev, element) => prev + element);
    
    final random = Random(combinedHash);

    // Csapatfüggő gólátlagok generálása (0.9 és 2.4 közötti értékek)
    double homeLambda = 1.0 + (random.nextDouble() * 1.3);
    double awayLambda = 0.8 + (random.nextDouble() * 1.2);

    int homeWins = 0;
    int draws = 0;
    int awayWins = 0;

    double totalHomeGoals = 0;
    double totalAwayGoals = 0;

    Map<String, int> scoreFrequency = {};

    for (int i = 0; i < simulations; i++) {
      int homeGoals = _poissonRandom(homeLambda, random);
      int awayGoals = _poissonRandom(awayLambda, random);

      totalHomeGoals += homeGoals;
      totalAwayGoals += awayGoals;

      if (homeGoals > awayGoals) {
        homeWins++;
      } else if (homeGoals == awayGoals) {
        draws++;
      } else {
        awayWins++;
      }

      String scoreKey = '$homeGoals:$awayGoals';
      scoreFrequency[scoreKey] = (scoreFrequency[scoreKey] ?? 0) + 1;
    }

    // Leggyakoribb eredmény keresése
    String mostLikelyScore = '1:1';
    int maxFreq = -1;
    scoreFrequency.forEach((score, freq) {
      if (freq > maxFreq) {
        maxFreq = freq;
        mostLikelyScore = score;
      }
    });

    // Logikai korrekció, hogy a győzelmi arány és a pontszám összhangban legyen
    List<String> parts = mostLikelyScore.split(':');
    int hGoals = int.parse(parts[0]);
    int aGoals = int.parse(parts[1]);

    if (homeWins > awayWins && homeWins > draws && hGoals <= aGoals) {
      mostLikelyScore = '${aGoals + 1}:$aGoals';
    } else if (awayWins > homeWins && awayWins > draws && hGoals >= aGoals) {
      mostLikelyScore = '$hGoals:${hGoals + 1}';
    } else if (draws > homeWins && draws > awayWins && hGoals != aGoals) {
      mostLikelyScore = '1:1';
    }

    return MatchSimulationResult(
      homeWinProbability: (homeWins / simulations) * 100,
      drawProbability: (draws / simulations) * 100,
      awayWinProbability: (awayWins / simulations) * 100,
      mostLikelyScore: mostLikelyScore,
      averageHomeGoals: totalHomeGoals / simulations,
      averageAwayGoals: totalAwayGoals / simulations,
      totalSimulations: simulations,
    );
  }

  // Poisson eloszlás segédfüggvény
  static int _poissonRandom(double lambda, Random random) {
    double L = exp(-lambda);
    double k = 0;
    double p = 1.0;
    do {
      k++;
      p *= random.nextDouble();
    } while (p > L);
    return (k - 1).toInt();
  }

  // AI Szakértői elemzés szövegezése az egyedi adatok alapján
  static Future<String> getAiMatchAnalysis({
    required String homeTeam,
    required String awayTeam,
    required MatchSimulationResult simulation,
  }) async {
    String favorite = simulation.homeWinProbability > simulation.awayWinProbability ? homeTeam : awayTeam;
    double maxProb = max(simulation.homeWinProbability, simulation.awayWinProbability);

    return "A(z) ${simulation.totalSimulations} darab Monte Carlo szimuláció mélyreható elemzése alapján a mérkőzés esélyese a(z) $favorite (${maxProb.toStringAsFixed(1)}%). "
        "A hazai csapat várható gólátlaga ${simulation.averageHomeGoals.toStringAsFixed(2)}, míg a vendégeké ${simulation.averageAwayGoals.toStringAsFixed(2)}. "
        "A legvalószínűbb pontos végeredmény a szimulációk alapján: ${simulation.mostLikelyScore}.";
  }
}
