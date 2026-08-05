/*
===========================================
MeccsIQ Pro v2.0
File: gemini_service.dart
Cél: A helyi Poisson/Monte Carlo szimuláció száraz
számait a Google Gemini modellel valódi, olvasható
magyar nyelvű szakértői elemzéssé alakítja.

Ha nincs beállítva Gemini API kulcs, vagy a hívás
bármilyen okból meghiúsul, a metódus null-t ad vissza
- a hívó oldalon (ai_analysis_screen.dart) ilyenkor a
korábbi, helyi sablon-elemzésre esik vissza az app,
tehát a funkció soha nem töri el a képernyőt.
===========================================
*/

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ai_simulation_service.dart';
import '../utils/odds_value_calculator.dart';

class GeminiService {
  static const String _modelName = 'gemini-2.5-flash';

  Future<String?> _getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString('gemini_key');
    if (key == null || key.trim().isEmpty) return null;
    return key.trim();
  }

  /// Valódi, LLM által írt mérkőzéselemzést generál a Monte Carlo
  /// szimuláció eredménye és (ha van) a piaci odds-value alapján.
  /// Visszatér null-lal, ha nincs kulcs vagy hiba történt.
  Future<String?> generateMatchAnalysis({
    required String homeTeam,
    required String awayTeam,
    required String leagueName,
    required MatchSimulationResult sim,
    OddsValueResult? value,
  }) async {
    final apiKey = await _getApiKey();
    if (apiKey == null) return null;

    try {
      final model = GenerativeModel(
        model: _modelName,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.6,
          maxOutputTokens: 500,
        ),
      );

      final prompt = _buildPrompt(
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        leagueName: leagueName,
        sim: sim,
        value: value,
      );

      final response = await model
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 20));

      final text = response.text?.trim();
      if (text == null || text.isEmpty) return null;
      return text;
    } catch (_) {
      // Hálózati hiba, érvénytelen kulcs, kvóta stb. - csendes fallback.
      return null;
    }
  }

  String _buildPrompt({
    required String homeTeam,
    required String awayTeam,
    required String leagueName,
    required MatchSimulationResult sim,
    OddsValueResult? value,
  }) {
    final buffer = StringBuffer();

    buffer.writeln(
        'Te egy tapasztalt, higgadt sportelemző vagy, aki egy StatPal adatokra épülő '
        'Poisson-eloszlású Monte Carlo szimuláció (50 000 lefuttatás) eredményét magyarázza el '
        'egy magyar nyelvű mobilalkalmazás felhasználóinak.');
    buffer.writeln();
    buffer.writeln('MÉRKŐZÉS: $homeTeam - $awayTeam ($leagueName)');
    buffer.writeln();
    buffer.writeln('SZIMULÁCIÓS ADATOK (ezeket használd, ne találj ki új számokat):');
    buffer.writeln('- Hazai győzelem: ${sim.homeWinProbability.toStringAsFixed(1)}%');
    buffer.writeln('- Döntetlen: ${sim.drawProbability.toStringAsFixed(1)}%');
    buffer.writeln('- Vendég győzelem: ${sim.awayWinProbability.toStringAsFixed(1)}%');
    buffer.writeln('- Várható gólátlag (xG): $homeTeam ${sim.averageHomeGoals} - $awayTeam ${sim.averageAwayGoals}');
    buffer.writeln('- Legvalószínűbb végeredmény: ${sim.mostLikelyScore}');
    buffer.writeln('- Over 2.5 gól: ${sim.over25Probability.toStringAsFixed(1)}%');
    buffer.writeln('- Mindkét csapat szerez gólt (BTTS): ${sim.bttsYesProbability.toStringAsFixed(1)}%');

    if (sim.homePosition != null || sim.awayPosition != null) {
      buffer.writeln('- Tabellahelyezés: $homeTeam ${sim.homePosition ?? "?"}. hely, $awayTeam ${sim.awayPosition ?? "?"}. hely');
    }
    if (sim.homeForm != null || sim.awayForm != null) {
      buffer.writeln('- Utolsó 5 forma: $homeTeam ${sim.homeForm ?? "nincs adat"}, $awayTeam ${sim.awayForm ?? "nincs adat"} (W=győzelem, D=döntetlen, L=vereség)');
    }
    if (sim.homeGoalsScoredAvg != null && sim.homeGoalsConcededAvg != null) {
      buffer.writeln('- $homeTeam hazai gólátlag: ${sim.homeGoalsScoredAvg!.toStringAsFixed(2)} rúgott / ${sim.homeGoalsConcededAvg!.toStringAsFixed(2)} kapott mérkőzésenként');
    }
    if (sim.awayGoalsScoredAvg != null && sim.awayGoalsConcededAvg != null) {
      buffer.writeln('- $awayTeam vendég gólátlag: ${sim.awayGoalsScoredAvg!.toStringAsFixed(2)} rúgott / ${sim.awayGoalsConcededAvg!.toStringAsFixed(2)} kapott mérkőzésenként');
    }
    if (sim.h2hMatchesUsed > 0) {
      buffer.writeln('- Egymás elleni (H2H) meccsek figyelembe véve: ${sim.h2hMatchesUsed} db${sim.usedWeightedH2h ? " (a friss eredmények nagyobb súllyal)" : ""}');
      if (sim.recentScores.isNotEmpty) {
        buffer.writeln('- Legutóbbi egymás elleni eredmények: ${sim.recentScores.join(", ")}');
      }
    }
    buffer.writeln('- Adatminőség: ${sim.dataQuality == "strong" ? "erős (sok H2H és tabella adat)" : sim.dataQuality == "medium" ? "közepes" : "gyenge (kevés adat, óvatosan kezelendő)"}');

    if (value != null && value.hasOdds) {
      buffer.writeln();
      buffer.writeln('PIACI ODDS ÉS ÉRTÉK (VALUE) SZÁMÍTÁS:');
      buffer.writeln('- Piaci odds: 1 = ${value.homeOdds!.toStringAsFixed(2)}, X = ${value.drawOdds!.toStringAsFixed(2)}, 2 = ${value.awayOdds!.toStringAsFixed(2)}');
      if (value.hasValue) {
        final sideLabel = value.bestSide == 'home' ? homeTeam : (value.bestSide == 'away' ? awayTeam : 'Döntetlen');
        buffer.writeln('- A modell szerint értékes (value) fogadás: $sideLabel, kb. +${value.bestEdge!.toStringAsFixed(1)} százalékpont előnnyel a piaci árazáshoz képest.');
      } else {
        buffer.writeln('- A modell szerint jelenleg nincs egyértelmű, legalább 5 százalékpontos előnyt jelentő value fogadás ezen a piacon.');
      }
    }

    buffer.writeln();
    buffer.writeln('FELADAT:');
    buffer.writeln(
        '- Írj egy 4-6 mondatos, folyó szövegű, magyar nyelvű elemzést a fenti adatok alapján. '
        'Emeld ki, melyik csapat esélyesebb és miért (forma, gólátlag, H2H, tabella - amiből van adat), '
        'térj ki a várható gólszámra/BTTS-re, és ha volt value jelzés, említsd meg röviden.');
    buffer.writeln(
        '- Ne találj ki olyan tényt (sérülés, hiányzó játékos, edzőváltás stb.), ami nem szerepel a fenti adatok között.');
    buffer.writeln(
        '- Ha az adatminőség gyenge, jelezd, hogy a becslés bizonytalanabb.');
    buffer.writeln(
        '- A végén egy rövid, egy mondatos felelősségteljes játék jellegű megjegyzéssel zárj (pl. hogy ez statisztikai becslés, nem garancia).');
    buffer.writeln('- Ne használj markdown fejléceket, ne sorold fel újra nyers számokat listaformában - ezt az app már megjeleníti külön. Egyszerű, olvasható bekezdés(eke)t írj.');

    return buffer.toString();
  }
}
