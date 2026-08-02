import 'dart:math';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  // Alapértelmezett tartalék API kulcs (ha a profilban nincs beállítva)
  static const String _geminiApiKey = 'ITT_LEGYEN_A_GEMINI_API_KULCSOD';

  // Monte Carlo motor (50 000 futtatás) - Csapatfüggő egyedi lambda értékekkel
  static MatchSimulationResult runMonteCarloSimulation({
    required String homeTeam,
    required String awayTeam,
    int simulations = 50000,
  }) {
    // Egyedi "seed" generálása a csapatnevekből, hogy minden meccs teljesen más esélyeket kapjon
    int combinedHash = homeTeam.codeUnits.fold(0, (prev, element) => prev + element) +
        awayTeam.codeUnits.fold(0, (prev, element) => prev + element);
    
    final random = Random(combinedHash);

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

    String mostLikelyScore = '1:1';
    int maxFreq = -1;
    scoreFrequency.forEach((score, freq) {
      if (freq > maxFreq) {
        maxFreq = freq;
        mostLikelyScore = score;
      }
    });

    // Logikai korrekció a győzelmi arány és a pontszám összhangjához
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

  // Valódi Google Gemini API hívás a mentett vagy alapértelmezett kulcs alapján
  static Future<String> getAiMatchAnalysis({
    required String homeTeam,
    required String awayTeam,
    required MatchSimulationResult simulation,
  }) async {
    // Kiolvassuk a Profilban elmentett Gemini API kulcsot
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString('gemini_key');
    
    final dynamicApiKey = (savedKey != null && savedKey.trim().isNotEmpty) ? savedKey.trim() : _geminiApiKey;

    if (dynamicApiKey.isEmpty || dynamicApiKey == 'ITT_LEGYEN_A_GEMINI_API_KULCSOD') {
      return "Kérlek, add meg a Google Gemini API kulcsodat a Profil menüpontban az AI elemzésekhez!";
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-3.6-flash',
        apiKey: dynamicApiKey,
      );

      final prompt = '''
Te egy profi futball-elemző és statisztikus vagy. Kérlek, írj egy tömör, de izgalmas és szakértői elemzést (max 3-4 mondatban, magyar nyelven) a következő mérkőzésről a 50 000 futtatásos Monte Carlo szimuláció adatai alapján:
- Hazai csapat: $homeTeam
- Vendég csapat: $awayTeam
- Hazai győzelem esélye: ${simulation.homeWinProbability.toStringAsFixed(1)}%
- Döntetlen esélye: ${simulation.drawProbability.toStringAsFixed(1)}%
- Vendég győzelem esélye: ${simulation.awayWinProbability.toStringAsFixed(1)}%
- Várható gólok: $homeTeam (${simulation.averageHomeGoals.toStringAsFixed(2)}) - $awayTeam (${simulation.averageAwayGoals.toStringAsFixed(2)})
- Legvalószínűbb pontos végeredmény: ${simulation.mostLikelyScore}

Írd meg, hogy ki az esélyes, mire érdemes figyelni, és miért ez a legvalószínűbb kimenetel!
''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      return response.text ?? "Nem sikerült elemzést generálni.";
    } catch (e) {
      return "Hiba történt az AI elemzés lekérése közben: $e";
    }
  }
}
