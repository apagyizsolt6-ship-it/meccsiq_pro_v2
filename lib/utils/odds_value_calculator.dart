/*
===========================================
MeccsIQ Pro v2.0
File: odds_value_calculator.dart
Cél: StatPal prematch odds válasz feldolgozása és a
Monte Carlo szimuláció esélyeivel való összevetése
("value" / edge számítás), egy helyen, hogy a lista
nézet (ai_screen) és a részletes elemzés
(ai_analysis_screen) ugyanazt a logikát használja.
===========================================
*/

class OddsValueResult {
  final double? homeOdds;
  final double? drawOdds;
  final double? awayOdds;
  final double? homeEdge;
  final double? drawEdge;
  final double? awayEdge;
  final String? bestSide; // 'home' | 'draw' | 'away'
  final double? bestEdge;

  const OddsValueResult({
    this.homeOdds,
    this.drawOdds,
    this.awayOdds,
    this.homeEdge,
    this.drawEdge,
    this.awayEdge,
    this.bestSide,
    this.bestEdge,
  });

  bool get hasOdds => homeOdds != null && drawOdds != null && awayOdds != null;
  bool get hasValue => bestSide != null;
}

class OddsValueCalculator {
  /// Egy bajnokság teljes prematch odds válaszát dolgozza fel egyszer,
  /// és egy kereshető map-et ad vissza: kulcs -> {home, draw, away odds}.
  /// Kulcsok: 'id:homeId_awayId' és 'name:homename_awayname' (lowercase).
  static Map<String, Map<String, double>> parseLeagueOdds(
      Map<String, dynamic>? oddsData) {
    final Map<String, Map<String, double>> result = {};
    if (oddsData == null) return result;

    try {
      final prematch = oddsData['prematch_odds'];
      if (prematch is! Map) return result;
      final league = prematch['league'];
      if (league is! Map) return result;
      final matches = league['match'];
      if (matches is! List) return result;

      for (final m in matches) {
        if (m is! Map) continue;

        final homeId = m['home']?['id']?.toString();
        final awayId = m['away']?['id']?.toString();
        final homeName = (m['home']?['name']?.toString() ?? '').toLowerCase();
        final awayName = (m['away']?['name']?.toString() ?? '').toLowerCase();

        final oddsList = m['odds'];
        if (oddsList is! List) continue;

        Map? oneXTwo;
        for (final o in oddsList) {
          if (o is Map && (o['name']?.toString().toLowerCase() == '1x2')) {
            oneXTwo = o;
            break;
          }
        }
        if (oneXTwo == null) continue;

        final bookmakers = oneXTwo['bookmaker'];
        if (bookmakers is! List || bookmakers.isEmpty) continue;
        final firstBook = bookmakers.first;
        if (firstBook is! Map) continue;
        final oddItems = firstBook['odd'];
        if (oddItems is! List) continue;

        double? homeOdds, drawOdds, awayOdds;
        for (final item in oddItems) {
          if (item is! Map) continue;
          final name = (item['name']?.toString() ?? '').toLowerCase();
          final value = double.tryParse(item['value']?.toString() ?? '');
          if (value == null || value <= 1.01) continue;
          if (name == 'home' || name == '1') homeOdds = value;
          if (name == 'draw' || name == 'x') drawOdds = value;
          if (name == 'away' || name == '2') awayOdds = value;
        }

        if (homeOdds == null || drawOdds == null || awayOdds == null) {
          continue;
        }

        final entry = {'home': homeOdds, 'draw': drawOdds, 'away': awayOdds};

        if (homeId != null && homeId.isNotEmpty && awayId != null && awayId.isNotEmpty) {
          result['id:${homeId}_$awayId'] = entry;
        }
        if (homeName.isNotEmpty && awayName.isNotEmpty) {
          result['name:${homeName}_$awayName'] = entry;
        }
      }
    } catch (_) {}

    return result;
  }

  /// Megkeresi egy adott meccs oddsait a bajnokság map-jében:
  /// 1. pontos ID egyezés, 2. pontos névegyezés, 3. részleges
  /// (contains) névegyezés - ugyanaz a rugalmasság, mint amit az
  /// eredeti implementáció is használt a csapatnevek eltérő
  /// írásmódja miatt (pl. "FC" toldalékok).
  static Map<String, double>? findOdds(
    Map<String, Map<String, double>> leagueOdds, {
    String? homeId,
    String? awayId,
    required String homeName,
    required String awayName,
  }) {
    if (homeId != null && homeId.isNotEmpty && awayId != null && awayId.isNotEmpty) {
      final byId = leagueOdds['id:${homeId}_$awayId'];
      if (byId != null) return byId;
    }

    final exactKey = 'name:${homeName.toLowerCase()}_${awayName.toLowerCase()}';
    final exact = leagueOdds[exactKey];
    if (exact != null) return exact;

    final homeLower = homeName.toLowerCase();
    for (final entry in leagueOdds.entries) {
      if (!entry.key.startsWith('name:')) continue;
      final namesPart = entry.key.substring(5);
      final split = namesPart.split('_');
      if (split.isEmpty) continue;
      final entryHomeName = split.first;
      if (entryHomeName.contains(homeLower) || homeLower.contains(entryHomeName)) {
        return entry.value;
      }
    }

    return null;
  }

  /// A modell (Monte Carlo) valószínűségeit veti össze a piaci
  /// (bookmaker) implikált valószínűségekkel, és megkeresi, van-e
  /// legalább [minEdge] százalékpontos előny valamelyik kimenetelen.
  static OddsValueResult calculateEdge({
    required Map<String, double>? odds,
    required double homeWinProbability,
    required double drawProbability,
    required double awayWinProbability,
    double minEdge = 5.0,
  }) {
    if (odds == null) return const OddsValueResult();

    final homeOdds = odds['home'];
    final drawOdds = odds['draw'];
    final awayOdds = odds['away'];
    if (homeOdds == null || drawOdds == null || awayOdds == null) {
      return const OddsValueResult();
    }

    final homeImplied = 100 / homeOdds;
    final drawImplied = 100 / drawOdds;
    final awayImplied = 100 / awayOdds;

    final homeEdge = homeWinProbability - homeImplied;
    final drawEdge = drawProbability - drawImplied;
    final awayEdge = awayWinProbability - awayImplied;

    double best = -100;
    String? side;
    if (homeEdge > best && homeEdge >= minEdge) {
      best = homeEdge;
      side = 'home';
    }
    if (drawEdge > best && drawEdge >= minEdge) {
      best = drawEdge;
      side = 'draw';
    }
    if (awayEdge > best && awayEdge >= minEdge) {
      best = awayEdge;
      side = 'away';
    }

    return OddsValueResult(
      homeOdds: homeOdds,
      drawOdds: drawOdds,
      awayOdds: awayOdds,
      homeEdge: homeEdge,
      drawEdge: drawEdge,
      awayEdge: awayEdge,
      bestSide: side,
      bestEdge: side != null ? best : null,
    );
  }
}
