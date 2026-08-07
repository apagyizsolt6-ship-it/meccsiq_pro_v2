/*
===========================================
MeccsIQ Pro v2.0
File: prediction_tracker_service.dart
Cél: Az AI Tippek listában megjelenő minden tippet naplóz, majd a
mérkőzés lejátszása után a valós StatPal eredménnyel összeveti -
így épül fel egy ellenőrizhető, átlátható "AI eddigi teljesítménye"
statisztika, nem csak egy fekete dobozos jóslat.

Tárolás: SharedPreferences-ben, egyetlen JSON tömbként (a projekt
mérete mellett ez elég - nem kell külön adatbázis). A napló mérete
korlátozva van (lásd _maxStoredRecords), a legrégebbi, már feloldott
bejegyzések esnek ki elsőként, ha betelik.
===========================================
*/

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'statpal_service.dart';

class PredictionRecord {
  final String id;
  final String date; // dd.mm.yyyy - a mérkőzés napja
  final String leagueId;
  final String leagueName;
  final String homeTeam;
  final String awayTeam;
  final String? homeTeamId;
  final String? awayTeamId;

  final String tipSide; // 'home' | 'draw' | 'away'
  final double tipProbability;
  final bool over25Tip;
  final double over25Probability;
  final bool bttsTip;
  final double bttsProbability;

  final String? valueSide; // 'home' | 'draw' | 'away' | null
  final double? valueEdge;
  final double? valueOdds;

  // Feloldás után töltődik ki
  String status; // 'pending' | 'resolved' | 'unresolved'
  int? actualHomeGoals;
  int? actualAwayGoals;
  bool? tipCorrect;
  bool? over25Correct;
  bool? bttsCorrect;
  bool? valueCorrect;

  PredictionRecord({
    required this.id,
    required this.date,
    required this.leagueId,
    required this.leagueName,
    required this.homeTeam,
    required this.awayTeam,
    this.homeTeamId,
    this.awayTeamId,
    required this.tipSide,
    required this.tipProbability,
    required this.over25Tip,
    required this.over25Probability,
    required this.bttsTip,
    required this.bttsProbability,
    this.valueSide,
    this.valueEdge,
    this.valueOdds,
    this.status = 'pending',
    this.actualHomeGoals,
    this.actualAwayGoals,
    this.tipCorrect,
    this.over25Correct,
    this.bttsCorrect,
    this.valueCorrect,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'leagueId': leagueId,
        'leagueName': leagueName,
        'homeTeam': homeTeam,
        'awayTeam': awayTeam,
        'homeTeamId': homeTeamId,
        'awayTeamId': awayTeamId,
        'tipSide': tipSide,
        'tipProbability': tipProbability,
        'over25Tip': over25Tip,
        'over25Probability': over25Probability,
        'bttsTip': bttsTip,
        'bttsProbability': bttsProbability,
        'valueSide': valueSide,
        'valueEdge': valueEdge,
        'valueOdds': valueOdds,
        'status': status,
        'actualHomeGoals': actualHomeGoals,
        'actualAwayGoals': actualAwayGoals,
        'tipCorrect': tipCorrect,
        'over25Correct': over25Correct,
        'bttsCorrect': bttsCorrect,
        'valueCorrect': valueCorrect,
      };

  static PredictionRecord fromJson(Map<String, dynamic> j) {
    return PredictionRecord(
      id: j['id']?.toString() ?? '',
      date: j['date']?.toString() ?? '',
      leagueId: j['leagueId']?.toString() ?? '',
      leagueName: j['leagueName']?.toString() ?? '',
      homeTeam: j['homeTeam']?.toString() ?? '',
      awayTeam: j['awayTeam']?.toString() ?? '',
      homeTeamId: j['homeTeamId']?.toString(),
      awayTeamId: j['awayTeamId']?.toString(),
      tipSide: j['tipSide']?.toString() ?? 'draw',
      tipProbability: (j['tipProbability'] as num?)?.toDouble() ?? 0,
      over25Tip: j['over25Tip'] == true,
      over25Probability: (j['over25Probability'] as num?)?.toDouble() ?? 0,
      bttsTip: j['bttsTip'] == true,
      bttsProbability: (j['bttsProbability'] as num?)?.toDouble() ?? 0,
      valueSide: j['valueSide']?.toString(),
      valueEdge: (j['valueEdge'] as num?)?.toDouble(),
      valueOdds: (j['valueOdds'] as num?)?.toDouble(),
      status: j['status']?.toString() ?? 'pending',
      actualHomeGoals: (j['actualHomeGoals'] as num?)?.toInt(),
      actualAwayGoals: (j['actualAwayGoals'] as num?)?.toInt(),
      tipCorrect: j['tipCorrect'] as bool?,
      over25Correct: j['over25Correct'] as bool?,
      bttsCorrect: j['bttsCorrect'] as bool?,
      valueCorrect: j['valueCorrect'] as bool?,
    );
  }
}

class PredictionStats {
  final int totalLogged;
  final int resolvedCount;
  final int pendingCount;

  final int tip1x2Correct;
  final int tip1x2Total;

  final int over25CorrectCount;
  final int over25Total;

  final int bttsCorrectCount;
  final int bttsTotal;

  final int valueBetsCount;
  final int valueBetsWon;
  final double valueRoiUnits; // profit/loss 1 egységes tétekkel

  const PredictionStats({
    required this.totalLogged,
    required this.resolvedCount,
    required this.pendingCount,
    required this.tip1x2Correct,
    required this.tip1x2Total,
    required this.over25CorrectCount,
    required this.over25Total,
    required this.bttsCorrectCount,
    required this.bttsTotal,
    required this.valueBetsCount,
    required this.valueBetsWon,
    required this.valueRoiUnits,
  });

  double get tip1x2HitRate =>
      tip1x2Total == 0 ? 0 : (tip1x2Correct / tip1x2Total) * 100;
  double get over25HitRate =>
      over25Total == 0 ? 0 : (over25CorrectCount / over25Total) * 100;
  double get bttsHitRate =>
      bttsTotal == 0 ? 0 : (bttsCorrectCount / bttsTotal) * 100;
  double get valueRoiPercent =>
      valueBetsCount == 0 ? 0 : (valueRoiUnits / valueBetsCount) * 100;
}

class PredictionTrackerService {
  static const String _storageKey = 'ai_prediction_log_v1';
  static const int _maxStoredRecords = 800;

  static Future<List<PredictionRecord>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map>()
          .map((e) => PredictionRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveAll(List<PredictionRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    // Ha betelt a napló, a legrégebbi, MÁR FELOLDOTT bejegyzéseket
    // dobjuk el elsőként - a pending tippeket sosem töröljük idő
    // előtt, azoknak még nincs meg az eredménye.
    List<PredictionRecord> trimmed = records;
    if (trimmed.length > _maxStoredRecords) {
      final resolved =
          trimmed.where((r) => r.status != 'pending').toList();
      final pending = trimmed.where((r) => r.status == 'pending').toList();
      final overflow = trimmed.length - _maxStoredRecords;
      if (resolved.length > overflow) {
        resolved.removeRange(0, overflow);
      }
      trimmed = [...resolved, ...pending];
    }
    final encoded = jsonEncode(trimmed.map((r) => r.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  static String buildId({
    required String date,
    required String leagueId,
    String? homeTeamId,
    String? awayTeamId,
    required String homeTeam,
    required String awayTeam,
  }) {
    final home = (homeTeamId != null && homeTeamId.isNotEmpty)
        ? homeTeamId
        : homeTeam.toLowerCase();
    final away = (awayTeamId != null && awayTeamId.isNotEmpty)
        ? awayTeamId
        : awayTeam.toLowerCase();
    return '$date|$leagueId|$home|$away';
  }

  /// Egy köteg új tippet ment el egyszerre (egy olvasás + egy írás),
  /// dedupolva a már meglévő azonosítók alapján - így az AI Tippek
  /// lista minden frissítése/pull-to-refresh-e nem hoz létre duplikált
  /// bejegyzést ugyanahhoz a meccshez ugyanarra a napra.
  static Future<void> recordPredictionsBatch(
      List<PredictionRecord> newRecords) async {
    if (newRecords.isEmpty) return;

    final existing = await _loadAll();
    final existingIds = existing.map((r) => r.id).toSet();

    bool changed = false;
    for (final rec in newRecords) {
      if (!existingIds.contains(rec.id)) {
        existing.add(rec);
        existingIds.add(rec.id);
        changed = true;
      }
    }

    if (changed) {
      await _saveAll(existing);
    }
  }

  /// A még függőben lévő (pending), de már lejátszottnak tekinthető
  /// (a mérkőzés napja a mai nap előtt van) tippeket megpróbálja
  /// feloldani a StatPal valós eredménye alapján. A hívások száma
  /// korlátozva van (maxToResolve), hogy egy képernyő-nyitás ne
  /// generáljon irreálisan sok API-hívást.
  static Future<int> resolvePendingPredictions(
      {int maxToResolve = 40}) async {
    final all = await _loadAll();
    final today = DateTime.now();
    final todayKey =
        '${today.day.toString().padLeft(2, '0')}.${today.month.toString().padLeft(2, '0')}.${today.year}';

    final candidates = all.where((r) {
      if (r.status != 'pending') return false;
      if (r.leagueId.isEmpty) return false;
      // Csak a mai napnál korábbi (biztosan lezajlott) meccseket
      // próbáljuk feloldani.
      return r.date != todayKey && _isPastDate(r.date, today);
    }).toList();

    if (candidates.isEmpty) return 0;

    final statpal = StatpalService();
    int resolvedNow = 0;

    for (final rec in candidates.take(maxToResolve)) {
      try {
        final result = await statpal.findMatchResult(
          leagueId: rec.leagueId,
          date: rec.date,
          homeTeamId: rec.homeTeamId,
          awayTeamId: rec.awayTeamId,
        );

        if (result == null) {
          // Ha egy adott meccs a lejátszás napja után 10 nappal sem
          // oldható fel (pl. elmaradt, vagy csapat-ID mismatch),
          // "unresolved"-nek jelöljük, hogy ne próbálkozzunk vele
          // örökké minden megnyitáskor.
          final daysSince = today
              .difference(_parseDdMmYyyy(rec.date) ?? today)
              .inDays;
          if (daysSince > 10) {
            rec.status = 'unresolved';
            resolvedNow++;
          }
          continue;
        }

        final hg = result['home_goals'] as int?;
        final ag = result['away_goals'] as int?;
        if (hg == null || ag == null) continue;

        rec.actualHomeGoals = hg;
        rec.actualAwayGoals = ag;

        final actualSide = hg > ag ? 'home' : (hg < ag ? 'away' : 'draw');
        rec.tipCorrect = rec.tipSide == actualSide;

        final actualOver25 = (hg + ag) >= 3;
        rec.over25Correct = rec.over25Tip == actualOver25;

        final actualBtts = hg > 0 && ag > 0;
        rec.bttsCorrect = rec.bttsTip == actualBtts;

        if (rec.valueSide != null) {
          rec.valueCorrect = rec.valueSide == actualSide;
        }

        rec.status = 'resolved';
        resolvedNow++;
      } catch (_) {}
    }

    if (resolvedNow > 0) {
      await _saveAll(all);
    }

    return resolvedNow;
  }

  static bool _isPastDate(String ddMmYyyy, DateTime today) {
    final d = _parseDdMmYyyy(ddMmYyyy);
    if (d == null) return false;
    final todayOnly = DateTime(today.year, today.month, today.day);
    return d.isBefore(todayOnly);
  }

  static DateTime? _parseDdMmYyyy(String s) {
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

  static Future<PredictionStats> getStats() async {
    final all = await _loadAll();
    final resolved = all.where((r) => r.status == 'resolved').toList();
    final pending = all.where((r) => r.status == 'pending').toList();

    int tip1x2Correct = 0;
    int over25Correct = 0;
    int bttsCorrect = 0;
    int valueBetsCount = 0;
    int valueBetsWon = 0;
    double valueRoiUnits = 0;

    for (final r in resolved) {
      if (r.tipCorrect == true) tip1x2Correct++;
      if (r.over25Correct == true) over25Correct++;
      if (r.bttsCorrect == true) bttsCorrect++;

      if (r.valueSide != null && r.valueOdds != null) {
        valueBetsCount++;
        if (r.valueCorrect == true) {
          valueBetsWon++;
          valueRoiUnits += (r.valueOdds! - 1);
        } else {
          valueRoiUnits -= 1;
        }
      }
    }

    return PredictionStats(
      totalLogged: all.length,
      resolvedCount: resolved.length,
      pendingCount: pending.length,
      tip1x2Correct: tip1x2Correct,
      tip1x2Total: resolved.length,
      over25CorrectCount: over25Correct,
      over25Total: resolved.length,
      bttsCorrectCount: bttsCorrect,
      bttsTotal: resolved.length,
      valueBetsCount: valueBetsCount,
      valueBetsWon: valueBetsWon,
      valueRoiUnits: valueRoiUnits,
    );
  }

  /// A legutóbbi feloldott (resolved) tippek, legfrissebb elöl - a
  /// teljesítmény-képernyő listájához.
  static Future<List<PredictionRecord>> getRecentResolved(
      {int limit = 20}) async {
    final all = await _loadAll();
    final resolved = all.where((r) => r.status == 'resolved').toList();
    resolved.sort((a, b) {
      final da = _parseDdMmYyyy(a.date);
      final db = _parseDdMmYyyy(b.date);
      if (da == null || db == null) return 0;
      return db.compareTo(da);
    });
    return resolved.take(limit).toList();
  }
}
