import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Egy csapat sérülés/hiányzás összesítője a Get League Stats
/// (player-szintű) végpont alapján.
class TeamInjuryInfo {
  final int injuredCount;
  final int keyInjuredCount;
  final double? averageRating;

  const TeamInjuryInfo({
    required this.injuredCount,
    required this.keyInjuredCount,
    this.averageRating,
  });
}

/// Egy csapat várható gól (xG) összesítője az elmúlt N meccséből,
/// a Get Match Details By League végpont team_stats.expected_goals
/// mezője alapján (recency-súlyozott átlag).
class TeamXgSummary {
  final double xgFor;
  final double xgAgainst;
  final int matchesUsed;

  const TeamXgSummary({
    required this.xgFor,
    required this.xgAgainst,
    required this.matchesUsed,
  });
}

class StatpalService {
  static const String baseUrl = 'https://statpal.io/api';
  static const String fallbackKey = 'b5b07a3f-b019-4a18-8969-6045169feda9';

  static const Map<String, String> priorityLeagues = {
    '2838': 'UEFA – Bajnokok Ligája',
    '2840': 'UEFA – Európa Liga',
    '20686': 'UEFA – Konferencia Liga',
    '3037': 'Anglia – Premier League',
    '3038': 'Anglia – Championship',
    '3062': 'Németország – Bundesliga',
    '3058': 'Németország – 2. Bundesliga',
    '3054': 'Franciaország – Ligue 1',
    '3050': 'Franciaország – Ligue 2',
    '3102': 'Olaszország – Serie A',
    '3098': 'Olaszország – Serie B',
    '3232': 'Spanyolország – La Liga',
    '3231': 'Spanyolország – La Liga 2',
    '3081': 'Magyarország – NB I',
    '3078': 'Magyarország – NB II',
  };

  static Map<String, dynamic>? _cachedData;
  static DateTime? _lastFetchTime;

  static const Duration _liveCacheDuration = Duration(seconds: 25);
  static const Duration _normalCacheDuration = Duration(minutes: 2);

  // Bajnokságonkénti cache a "Get League Stats" (player/sérülés) válaszhoz.
  // Ez az endpoint a dokumentáció szerint 4 óránként frissül, ezért
  // hosszabb ideig cache-elhető anélkül, hogy elavulna.
  static final Map<String, Map<String, dynamic>> _teamStatsCache = {};
  static final Map<String, DateTime> _teamStatsCacheTime = {};
  static const Duration _teamStatsCacheDuration = Duration(hours: 4);

  // Bajnokságonkénti cache a napokra visszamenőleg összegyűjtött,
  // xG-t is tartalmazó meccs-poolhoz (lezajlott meccsek).
  static final Map<String, List<Map<String, dynamic>>> _matchPoolCache = {};
  static final Map<String, DateTime> _matchPoolCacheTime = {};
  static const Duration _matchPoolCacheDuration = Duration(hours: 3);

  Future<String?> _getAccessKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString('statpal_key');
    if (key == null || key.isEmpty) return fallbackKey;
    return key;
  }

  Future<Map<String, dynamic>?> getLiveMatches(
      {bool forceRefresh = false}) async {
    if (forceRefresh) {
      _cachedData = null;
      _lastFetchTime = null;
    }

    if (!forceRefresh &&
        _cachedData != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _liveCacheDuration) {
      return _cachedData;
    }

    final apiKey = await _getAccessKey();
    final url =
        Uri.parse('$baseUrl/v2/soccer/matches/live?access_key=$apiKey');

    try {
      final response =
          await http.get(url, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _cachedData = data;
        _lastFetchTime = DateTime.now();
        return data;
      }
    } catch (_) {}
    return _cachedData;
  }

  Future<Map<String, dynamic>?> getDailyMatches(int offset) async {
    final apiKey = await _getAccessKey();
    final url = Uri.parse(
        '$baseUrl/v2/soccer/matches/daily?offset=$offset&access_key=$apiKey');

    try {
      final response =
          await http.get(url, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> getMatchesByLeague(String leagueId) async {
    final apiKey = await _getAccessKey();
    final url = Uri.parse(
        '$baseUrl/v2/soccer/leagues/$leagueId/matches?access_key=$apiKey');

    try {
      final response =
          await http.get(url, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<List<Map<String, dynamic>>> getPriorityLeagueMatches({
    DateTime? filterDate,
  }) async {
    final List<Map<String, dynamic>> result = [];

    String? filterKey;
    String? filterIso;
    if (filterDate != null) {
      final dd = filterDate.day.toString().padLeft(2, '0');
      final mm = filterDate.month.toString().padLeft(2, '0');
      final yyyy = filterDate.year.toString();
      filterKey = '$dd.$mm.$yyyy';
      filterIso = '$yyyy-$mm-$dd';
    }

    for (final entry in priorityLeagues.entries) {
      final leagueId = entry.key;
      final leagueName = entry.value;

      try {
        final data = await getMatchesByLeague(leagueId);
        if (data == null) continue;

        var matches = _extractMatchesFromLeagueResponse(data);

        if (filterKey != null) {
          matches = matches.where((m) {
            final d = (m['date']?.toString() ?? '').trim();
            if (d == filterKey) return true;
            if (filterIso != null && d.startsWith(filterIso)) return true;
            return false;
          }).toList();
        }

        if (matches.isEmpty) continue;

        result.add({
          'name': leagueName,
          'id': leagueId,
          'matches': matches,
        });
      } catch (_) {}
    }

    return result;
  }

  List<Map<String, dynamic>> _extractMatchesFromLeagueResponse(
      Map<String, dynamic> data) {
    final List<Map<String, dynamic>> allMatches = [];

    final matchesRoot = data['matches'];
    if (matchesRoot is! Map) return allMatches;

    final tournament = matchesRoot['tournament'];
    if (tournament is! Map) return allMatches;

    final weeks = tournament['week'];
    if (weeks is List) {
      for (final week in weeks) {
        if (week is! Map) continue;
        _collectMatchList(week['match'], allMatches);
      }
    }

    final stages = tournament['stage'];
    if (stages is List) {
      for (final stage in stages) {
        if (stage is! Map) continue;
        _collectMatchList(stage['match'], allMatches);

        final innerWeeks = stage['week'];
        if (innerWeeks is List) {
          for (final week in innerWeeks) {
            if (week is! Map) continue;
            _collectMatchList(week['match'], allMatches);
          }
        }
      }
    }

    for (final m in allMatches) {
      final home = m['home'];
      final away = m['away'];
      if (home is Map) {
        home['goals'] = home['goals'] ?? home['score'] ?? '';
        home['name'] = home['name']?.toString() ?? 'Hazai';
      }
      if (away is Map) {
        away['goals'] = away['goals'] ?? away['score'] ?? '';
        away['name'] = away['name']?.toString() ?? 'Vendég';
      }
      m['status'] = m['status']?.toString() ?? '';
      m['time'] = m['time']?.toString() ?? '';
      m['date'] = m['date']?.toString() ?? '';
    }

    return allMatches;
  }

  void _collectMatchList(dynamic raw, List<Map<String, dynamic>> out) {
    if (raw is List) {
      for (final m in raw) {
        if (m is Map) out.add(Map<String, dynamic>.from(m));
      }
    } else if (raw is Map) {
      out.add(Map<String, dynamic>.from(raw));
    }
  }

  Future<Map<String, dynamic>?> getLeagues() async {
    final apiKey = await _getAccessKey();
    final url = Uri.parse('$baseUrl/v2/soccer/leagues?access_key=$apiKey');
    try {
      final response =
          await http.get(url, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> getHeadToHeadStats(
      String team1Id, String team2Id) async {
    final apiKey = await _getAccessKey();
    final url = Uri.parse(
        '$baseUrl/v2/soccer/head-to-head?access_key=$apiKey&team1_id=$team1Id&team2_id=$team2Id');
    try {
      final response =
          await http.get(url, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> getStandings(String leagueId) async {
    final apiKey = await _getAccessKey();
    final url = Uri.parse(
        '$baseUrl/v2/soccer/leagues/$leagueId/standings?access_key=$apiKey');
    try {
      final response =
          await http.get(url, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> getLeagueMatchStats(String leagueId,
      {String? date}) async {
    final apiKey = await _getAccessKey();
    String urlStr =
        '$baseUrl/v2/soccer/leagues/$leagueId/matches/stats?access_key=$apiKey';
    if (date != null && date.isNotEmpty) urlStr += '&date=$date';
    try {
      final response = await http
          .get(Uri.parse(urlStr), headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Prematch odds lekérése egy bajnoksághoz
  Future<Map<String, dynamic>?> getPrematchOdds(String leagueId) async {
    final apiKey = await _getAccessKey();
    final url = Uri.parse(
        '$baseUrl/v2/soccer/leagues/$leagueId/odds/prematch?access_key=$apiKey');
    try {
      final response =
          await http.get(url, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Get League Stats: csapat + player szintű szezon-statisztika,
  /// benne az "injured" mezővel és a player "rating" értékekkel.
  /// A dokumentáció szerint 4 óránként frissül, ezért erősen
  /// cache-elhető (lásd [_teamStatsCacheDuration]).
  Future<Map<String, dynamic>?> getLeagueTeamStats(
    String leagueId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _teamStatsCache.containsKey(leagueId) &&
        _teamStatsCacheTime[leagueId] != null &&
        DateTime.now().difference(_teamStatsCacheTime[leagueId]!) <
            _teamStatsCacheDuration) {
      return _teamStatsCache[leagueId];
    }

    final apiKey = await _getAccessKey();
    final url = Uri.parse(
        '$baseUrl/v2/soccer/leagues/$leagueId/stats?access_key=$apiKey');

    try {
      final response =
          await http.get(url, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _teamStatsCache[leagueId] = data;
        _teamStatsCacheTime[leagueId] = DateTime.now();
        return data;
      }
    } catch (_) {}
    return _teamStatsCache[leagueId];
  }

  /// Visszamenőleg (napról napra) összegyűjti egy bajnokság lezajlott
  /// meccseinek részletes statisztikáját (Get Match Details By League,
  /// dátum-szűréssel), hogy legyen elég adat az xG-alapú forma
  /// számításához. Bajnokságonként cache-elt, hogy sok meccs esetén se
  /// hívjuk feleslegesen sokszor ugyanazt a napot.
  Future<List<Map<String, dynamic>>> getRecentLeagueMatchPool(
    String leagueId, {
    int lookbackDays = 7,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _matchPoolCache.containsKey(leagueId) &&
        _matchPoolCacheTime[leagueId] != null &&
        DateTime.now().difference(_matchPoolCacheTime[leagueId]!) <
            _matchPoolCacheDuration) {
      return _matchPoolCache[leagueId]!;
    }

    final List<Map<String, dynamic>> pool = [];
    final now = DateTime.now();

    for (int i = 1; i <= lookbackDays; i++) {
      final day = now.subtract(Duration(days: i));
      final dd = day.day.toString().padLeft(2, '0');
      final mm = day.month.toString().padLeft(2, '0');
      final yyyy = day.year.toString();
      final dateStr = '$dd.$mm.$yyyy';

      try {
        final data = await getLeagueMatchStats(leagueId, date: dateStr);
        if (data == null) continue;
        pool.addAll(_extractMatchStatsList(data));
      } catch (_) {}
    }

    _matchPoolCache[leagueId] = pool;
    _matchPoolCacheTime[leagueId] = DateTime.now();
    return pool;
  }

  /// A "matches/stats" végpont válaszát alakítja egységes,
  /// normalizált meccs-listává (xG, gólok, csapat ID/név). A StatPal
  /// válasz szerkezete napi lekérdezésnél lehet egyetlen meccs-objektum
  /// vagy meccs-lista is, ezért mindkettőt kezeljük.
  List<Map<String, dynamic>> _extractMatchStatsList(
      Map<String, dynamic> data) {
    final List<Map<String, dynamic>> out = [];

    final root = data['match-stats'];
    if (root is! Map) return out;
    final tournament = root['tournament'];
    if (tournament is! Map) return out;

    final List<dynamic> rawMatches = [];

    final matchesField = tournament['matches'];
    if (matchesField is List) {
      rawMatches.addAll(matchesField);
    } else if (matchesField is Map) {
      rawMatches.add(matchesField);
    }

    // Néhány liga hetekbe/szakaszokba csoportosítva is visszaadhatja
    // ugyanezt a struktúrát - védekező jelleggel ezt is kezeljük,
    // hasonlóan a getMatchesByLeague válaszához.
    final weeks = tournament['week'];
    if (weeks is List) {
      for (final w in weeks) {
        if (w is! Map) continue;
        final wm = w['match'];
        if (wm is List) rawMatches.addAll(wm);
        if (wm is Map) rawMatches.add(wm);
      }
    }

    for (final m in rawMatches) {
      if (m is! Map) continue;
      final home = m['home'];
      final away = m['away'];
      if (home is! Map || away is! Map) continue;

      double? homeXg;
      double? awayXg;
      final teamStats = m['team_stats'];
      if (teamStats is Map) {
        final homeTs = teamStats['home'];
        final awayTs = teamStats['away'];
        if (homeTs is Map) {
          final xg = homeTs['expected_goals'];
          if (xg is Map) {
            homeXg = double.tryParse(xg['total']?.toString() ?? '');
          }
        }
        if (awayTs is Map) {
          final xg = awayTs['expected_goals'];
          if (xg is Map) {
            awayXg = double.tryParse(xg['total']?.toString() ?? '');
          }
        }
      }

      out.add({
        'date': m['date']?.toString() ?? '',
        'status': m['status']?.toString() ?? '',
        'home_id': home['id']?.toString(),
        'home_name': home['name']?.toString(),
        'home_goals': double.tryParse(home['goals']?.toString() ?? ''),
        'away_id': away['id']?.toString(),
        'away_name': away['name']?.toString(),
        'away_goals': double.tryParse(away['goals']?.toString() ?? ''),
        'home_xg': homeXg,
        'away_xg': awayXg,
      });
    }

    return out;
  }

  /// A getLeagueTeamStats válaszából csapatonként összesíti a sérült
  /// játékosok számát, illetve a "kulcsjátékosnak" számító (legalább
  /// 450 percet, kb. 5 meccsnyit játszó) sérültek számát, valamint
  /// az átlagos player rating-et. Kulcs: csapat ID.
  static Map<String, TeamInjuryInfo> parseInjuryInfo(
      Map<String, dynamic>? data) {
    final Map<String, TeamInjuryInfo> result = {};
    if (data == null) return result;

    try {
      final leagueStats = data['league_stats'];
      if (leagueStats is! Map) return result;
      final league = leagueStats['league'];
      if (league is! Map) return result;
      final teams = league['team'];
      if (teams is! List) return result;

      for (final team in teams) {
        if (team is! Map) continue;
        final teamId = team['id']?.toString();
        if (teamId == null || teamId.isEmpty) continue;

        final squad = team['squad'];
        final players = (squad is Map) ? squad['player'] : null;

        List<dynamic> playerList = [];
        if (players is List) {
          playerList = players;
        } else if (players is Map) {
          playerList = [players];
        }

        int injuredCount = 0;
        int keyInjuredCount = 0;
        double ratingSum = 0;
        int ratingCount = 0;

        for (final p in playerList) {
          if (p is! Map) continue;

          final injured =
              (p['injured']?.toString() ?? '').toLowerCase() == 'true';
          final minutes =
              int.tryParse(p['minutes_played']?.toString() ?? '') ?? 0;
          final rating = double.tryParse(p['rating']?.toString() ?? '');

          if (rating != null && rating > 0) {
            ratingSum += rating;
            ratingCount++;
          }

          if (injured) {
            injuredCount++;
            // "Kulcsjátékos": legalább 450 percet (kb. 5 teljes meccs)
            // játszott a szezonban - így a bő keretben ülő, alig
            // szereplő sérültek nem torzítják túl a becslést.
            if (minutes >= 450) {
              keyInjuredCount++;
            }
          }
        }

        result[teamId] = TeamInjuryInfo(
          injuredCount: injuredCount,
          keyInjuredCount: keyInjuredCount,
          averageRating: ratingCount > 0 ? ratingSum / ratingCount : null,
        );
      }
    } catch (_) {}

    return result;
  }

  /// Egy adott csapat elmúlt meccseiből (a [getRecentLeagueMatchPool]
  /// által gyűjtött pool-ból) kiszámolja a saját xG-átlagát (támadás)
  /// és az ellenfelek ellene termelt xG-átlagát (védekezés). A
  /// legfrissebb meccsek nagyobb súlyt kapnak - hasonló elv, mint a
  /// H2H súlyozásnál. Ha egy meccshez nincs explicit xG adat, a nyers
  /// gólszámmal pótoljuk (gyengébb jelzés, de jobb, mint a semmi).
  static TeamXgSummary? computeTeamXgSummary(
    List<Map<String, dynamic>> pool,
    String? teamId, {
    int maxMatches = 8,
  }) {
    if (teamId == null || teamId.isEmpty) return null;

    final List<Map<String, dynamic>> teamMatches = [];
    for (final m in pool) {
      final homeId = m['home_id']?.toString();
      final awayId = m['away_id']?.toString();
      if (homeId == teamId || awayId == teamId) {
        teamMatches.add(m);
      }
    }
    if (teamMatches.isEmpty) return null;

    teamMatches.sort((a, b) {
      final da = _parseDdMmYyyy(a['date']?.toString());
      final db = _parseDdMmYyyy(b['date']?.toString());
      if (da == null || db == null) return 0;
      return db.compareTo(da); // legfrissebb elöl
    });

    final limited = teamMatches.take(maxMatches).toList();

    double xgForWeighted = 0;
    double xgAgainstWeighted = 0;
    double weightSum = 0;
    int usedCount = 0;

    for (int i = 0; i < limited.length; i++) {
      final m = limited[i];
      final isHome = m['home_id']?.toString() == teamId;

      final double? ownXg =
          isHome ? m['home_xg'] as double? : m['away_xg'] as double?;
      final double? oppXg =
          isHome ? m['away_xg'] as double? : m['home_xg'] as double?;
      final double? ownGoals =
          isHome ? m['home_goals'] as double? : m['away_goals'] as double?;
      final double? oppGoals =
          isHome ? m['away_goals'] as double? : m['home_goals'] as double?;

      final double? effectiveOwnXg = ownXg ?? ownGoals;
      final double? effectiveOppXg = oppXg ?? oppGoals;

      if (effectiveOwnXg == null || effectiveOppXg == null) continue;

      final w = i < 3 ? 1.6 : 1.0;
      xgForWeighted += effectiveOwnXg * w;
      xgAgainstWeighted += effectiveOppXg * w;
      weightSum += w;
      usedCount++;
    }

    if (usedCount == 0 || weightSum == 0) return null;

    return TeamXgSummary(
      xgFor: xgForWeighted / weightSum,
      xgAgainst: xgAgainstWeighted / weightSum,
      matchesUsed: usedCount,
    );
  }

  static DateTime? _parseDdMmYyyy(String? s) {
    if (s == null || s.isEmpty) return null;
    final parts = s.split('.');
    if (parts.length != 3) return null;
    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    if (d == null || m == null || y == null) return null;
    try {
      return DateTime(y, m, d);
    } catch (_) {
      return null;
    }
  }
}
