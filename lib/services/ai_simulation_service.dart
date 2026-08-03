import 'dart:convert';
import 'dart:math';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MatchSimulationResult {
  final double homeWinProbability;
  final double drawProbability;
  final double awayWinProbability;
  final String mostLikelyScore;
  final double averageHomeGoals;
  final double averageAwayGoals;
  final int totalSimulations;
  final bool isStatpalLive;

  MatchSimulationResult({
    required this.homeWinProbability,
    required this.drawProbability,
    required this.awayWinProbability,
    required this.mostLikelyScore,
    required this.averageHomeGoals,
    required this.averageAwayGoals,
    required this.totalSimulations,
    required this.isStatpalLive,
  });
}

class AiSimulationService {
  static const String _geminiApiKey = 'ITT_LEGYEN_A_GEMINI_API_KULCSOD';
  static final Map<String, String> _analysisCache = {};

  // Valós Statpal API Head-to-Head alapú Monte Carlo szimuláció
  static Future<MatchSimulationResult> runMonteCarloSimulation({
    required String homeTeam,
    required String awayTeam,
    int? team1Id,
    int? team2Id,
    int simulations = 50000,
  }) async {
    double homeLambda = 1.4;
    double awayLambda = 1.1;
    bool statpalLive = false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final statpalKey = prefs.getString('statpal_key') ?? 'b5b07a3f-b019-4a18-8969-6045169feda9';

      // Ha rendelkezésre állnak csapat ID-k, lekérdezzük a valós H2H statisztikát a Statpal API-ból
      if (team1Id != null && team2Id != null && statpalKey.isNotEmpty) {
        final url = Uri.parse('https://statpal.io/api/v2/soccer/head-to-head?access_key=$statpalKey&team1_id=$team1Id&team2_id=$team2Id');
        final response = await http.get(url, headers: {'Accept': 'application/json'});

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final h2h = data['head-to-head'];

          if (h2h != null && h2h['goals'] != null) {
            // Adatok kinyerése a Statpal JSON struktúrából
            final goalsTotal = h2h['goals']['total']['total'] as List<dynamic>;
            final overallTotal = h2h['overall_record']['total']['total'] as List<dynamic>;

            int totalGames = 1;
            for (var item in overallTotal) {
              if (item['games'] != null) {
                totalGames = int.tryParse(item['games'].toString()) ?? 1;
              }
            }

            double t1Scored = 0;
            double t2Scored = 0;

            for (var item in goalsTotal) {
              if (item['team1_scored'] != null) t1Scored = double.tryParse(item['team1_scored'].toString()) ?? 0;
              if (item['team2_scored'] != null) t2Scored = double.tryParse(item['team2_scored'].toString()) ?? 0;
            }

            if (totalGames > 0) {
              // Valós gólátlagok kiszámítása a Statpal múltbeli adatai alapján
              homeLambda = t1Scored / totalGames;
              awayLambda = t2Scored / totalGames;

              // Biztosítjuk, hogy ésszerű határok közt maradjon a lambda (0.5 és 3.5 között)
              homeLambda = homeLambda.clamp(0.5, 3.5);
              awayLambda = awayLambda.clamp(0.5, 3.5);
              statpalLive = true;
            }
          }
        }
      }
    } catch (_) {
      statpalLive = false;
    }

    // Ha nincs ID vagy hiba történt, biztonsági fallback számítás
    final random = Random(homeTeam.hashCode + awayTeam.hashCode);
    if (!statpalLive) {
      homeLambda = 1.1 + (random.nextDouble() * 0.8);
      awayLambda = 0.9 + (random.nextDouble() * 0.8);
    }

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

    return MatchSimulationResult(
      homeWinProbability: (homeWins / simulations) * 100,
      drawProbability: (draws / simulations) * 100,
      awayWinProbability: (awayWins / simulations) * 100,
      mostLikelyScore: mostLikelyScore,
      averageHomeGoals: totalHomeGoals / simulations,
      averageAwayGoals: totalAwayGoals / simulations,
      totalSimulations: simulations,
      isStatpalLive: statpalLive,
    );
  }

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

  static Future<String> getAiMatchAnalysis({
    required String homeTeam,
    required String awayTeam,
    required MatchSimulationResult simulation,
  }) async {
    final cacheKey = '${homeTeam}_$awayTeam';
    
    if (_analysisCache.containsKey(cacheKey)) {
      return _analysisCache[cacheKey]!;
    }

    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString('gemini_key');
    final dynamicApiKey = (savedKey != null && savedKey.trim().isNotEmpty) ? savedKey.trim() : _geminiApiKey;

    // Pontos és őszinte státuszjelzés a képernyőre
    final String dataSourceBadge = simulation.isStatpalLive 
        ? "🟢 **[Statpal API Head-to-Head valós adatok]**\n" 
        : "🔵 **[Helyi statisztikai modell]**\n";

    if (dynamicApiKey.isEmpty || dynamicApiKey == 'ITT_LEGYEN_A_GEMINI_API_KULCSOD') {
      return "$dataSourceBadge Kérlek, add meg a Google Gemini API kulcsodat a Profil menüpontban az AI elemzésekhez!";
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-3.6-flash',
        apiKey: dynamicApiKey,
      );

      final prompt = '''
Te egy profi futball-elemző és statisztikus vagy. Kérlek, írj egy tömör, de izgalmas és szakértői elemzést (max 3-4 mondatban, magyar nyelven) a következő mérkőzésről az 50 000 futtatásos Monte Carlo szimuláció adatai alapján:
- Hazai csapat: $homeTeam
- Vendég csapat: $awayTeam
- Hazai győzelem esélye: ${simulation.homeWinProbability.toStringAsFixed(1)}%
- Döntetlen esélye: ${simulation.drawProbability.toStringAsFixed(1)}%
- Vendég győzelem esélye: ${simulation.awayWinProbability.toStringAsFixed(1)}%
- Várható gólok: $homeTeam (${simulation.averageHomeGoals.toStringAsFixed(2)}) - $awayTeam (${simulation.averageAwayGoals.toStringAsFixed(2)})
- Legvalószínűbb pontos végeredmény: ${simulation.mostLikelyScore}

Írd meg a statisztikai adatok alapján, hogy ki az esélyes és miért!
''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      final text = response.text;

      if (text != null && text.isNotEmpty) {
        final finalResult = "$dataSourceBadge$text";
        _analysisCache[cacheKey] = finalResult;
        return finalResult;
      }
      
      return "$dataSourceBadge${_generateFallbackAnalysis(homeTeam, awayTeam, simulation)}";
    } catch (_) {
      return "$dataSourceBadge${_generateFallbackAnalysis(homeTeam, awayTeam, simulation)}";
    }
  }

  static String _generateFallbackAnalysis(String homeTeam, String awayTeam, MatchSimulationResult simulation) {
    String favorite = simulation.homeWinProbability > simulation.awayWinProbability ? homeTeam : awayTeam;
    double favProb = simulation.homeWinProbability > simulation.awayWinProbability ? simulation.homeWinProbability : simulation.awayWinProbability;
    
    return "A 50 000 futtatásos Monte Carlo szimuláció szerint a meccs esélyese a(z) $favorite (${favProb.toStringAsFixed(1)}%). A legvalószínűbb végeredmény a(z) ${simulation.mostLikelyScore}, a várható gólok: $homeTeam (${simulation.averageHomeGoals.toStringAsFixed(2)}) – $awayTeam (${simulation.averageAwayGoals.toStringAsFixed(2)}).";
  }
}
