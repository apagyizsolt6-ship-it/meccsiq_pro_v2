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
  // Monte Carlo motor (50 000 futtatás)
  static MatchSimulationResult runMonteCarloSimulation({
    required String homeTeam,
    required String awayTeam,
    double homeFormFactor = 1.2, // Hazai pálya előny / forma
    double awayFormFactor = 1.0,
    int simulations = 50000,
  }) {
    final random = Random();
    int homeWins = 0;
    int draws = 0;
    int awayWins = 0;

    double totalHomeGoals = 0;
    double totalAwayGoals = 0;

    Map<String, int> scoreFrequency = {};

    // Alap lambda értékek (gólátlagok becslése a forma alapján)
    double homeLambda = 1.5 * homeFormFactor;
    double awayLambda = 1.1 * awayFormFactor;

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

  // Poisson eloszlás segédfüggvény a valósághű gólszámokhoz
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

  // Itt fogjuk később bekötni a Google Gemini API hívást a mély elemzésekhez
  static Future<String> getAiMatchAnalysis({
    required String homeTeam,
    required String awayTeam,
    required MatchSimulationResult simulation,
  }) async {
    // Szimulált izmos válasz, amíg be nem kötjük a kulcsot
    return "A(z) ${simulation.totalSimulations} darab Monte Carlo szimuláció alapján a mérkőzés esélyese a(z) $homeTeam. "
        "A hazai győzelem valószínűsége ${simulation.homeWinProbability.toStringAsFixed(1)}%, "
        "míg a vendég siker ${simulation.awayWinProbability.toStringAsFixed(1)}%. "
        "A legvalószínűbb pontos végeredmény: ${simulation.mostLikelyScore}.";
  }
}
