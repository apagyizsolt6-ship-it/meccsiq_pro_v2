/*
===========================================
MeccsIQ Pro v2.0
File: ai_performance_screen.dart
Cél: Átlátható "track record" - megmutatja, hogy az AI Tippek
listában eddig felkínált tippek ténylegesen mennyire jöttek be a
valós StatPal eredmények alapján. Ez teszi ellenőrizhetővé a
modellt ahelyett, hogy csak "higgy nekünk" alapon működne.
===========================================
*/

import 'package:flutter/material.dart';

import '../../services/prediction_tracker_service.dart';

class AiPerformanceScreen extends StatefulWidget {
  const AiPerformanceScreen({super.key});

  @override
  State<AiPerformanceScreen> createState() => _AiPerformanceScreenState();
}

class _AiPerformanceScreenState extends State<AiPerformanceScreen> {
  bool _isLoading = true;
  PredictionStats? _stats;
  List<PredictionRecord> _recent = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    try {
      await PredictionTrackerService.resolvePendingPredictions();
    } catch (_) {}

    final stats = await PredictionTrackerService.getStats();
    final recent = await PredictionTrackerService.getRecentResolved();

    if (mounted) {
      setState(() {
        _stats = stats;
        _recent = recent;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('AI teljesítmény',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 12),
                  _buildMarketsCard(),
                  if (_stats != null && _stats!.valueBetsCount > 0) ...[
                    const SizedBox(height: 12),
                    _buildValueRoiCard(),
                  ],
                  const SizedBox(height: 12),
                  _buildRecentListCard(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    final s = _stats!;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Eddig naplózott tippek',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statBox('Összes', '${s.totalLogged}'),
                _statBox('Feloldva', '${s.resolvedCount}'),
                _statBox('Függőben', '${s.pendingCount}'),
              ],
            ),
            if (s.resolvedCount == 0) ...[
              const SizedBox(height: 12),
              const Text(
                'Még nincs elég lejátszott meccs a statisztikához - '
                'az AI Tippek listában megjelenő tippek automatikusan '
                'naplózódnak, és a meccs lejátszása után itt jelenik '
                'meg, hogy bejöttek-e.',
                style: TextStyle(fontSize: 11.5, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMarketsCard() {
    final s = _stats!;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Találati arány piaconként',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const Divider(height: 20),
            _hitRateRow('1X2 tipp', s.tip1x2HitRate, s.tip1x2Correct,
                s.tip1x2Total),
            const SizedBox(height: 10),
            _hitRateRow('Over/Under 2.5', s.over25HitRate,
                s.over25CorrectCount, s.over25Total),
            const SizedBox(height: 10),
            _hitRateRow(
                'BTTS', s.bttsHitRate, s.bttsCorrectCount, s.bttsTotal),
          ],
        ),
      ),
    );
  }

  Widget _buildValueRoiCard() {
    final s = _stats!;
    final positive = s.valueRoiUnits >= 0;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Value-tippek szimulált hozama',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 2),
            const Text(
              'Ha minden "ÉRTÉK" jelzésű tippre 1 egységet tettél volna '
              'a naplózáskori piaci odds-szal',
              style: TextStyle(fontSize: 10.5, color: Colors.grey),
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statBox('Fogadások', '${s.valueBetsCount}'),
                _statBox('Nyert', '${s.valueBetsWon}'),
                Column(
                  children: [
                    const Text('ROI',
                        style: TextStyle(fontSize: 10, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(
                      '${positive ? '+' : ''}${s.valueRoiPercent.toStringAsFixed(1)}%',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: positive ? Colors.green : Colors.redAccent),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentListCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Legutóbbi feloldott tippek',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const Divider(height: 20),
            if (_recent.isEmpty)
              const Text(
                'Még nincs feloldott tipp.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              )
            else
              ..._recent.map(_buildRecentRow),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentRow(PredictionRecord r) {
    final correct = r.tipCorrect == true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            correct ? Icons.check_circle : Icons.cancel,
            size: 18,
            color: correct ? Colors.green : Colors.redAccent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${r.homeTeam} ${r.actualHomeGoals ?? '?'}-${r.actualAwayGoals ?? '?'} ${r.awayTeam}',
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87),
                ),
                const SizedBox(height: 2),
                Text(
                  '${r.date} • ${r.leagueName} • tipp: ${_sideLabel(r.tipSide)} (${r.tipProbability.toStringAsFixed(0)}%)',
                  style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _sideLabel(String side) {
    if (side == 'home') return 'Hazai';
    if (side == 'away') return 'Vendég';
    return 'Döntetlen';
  }

  Widget _hitRateRow(String label, double pct, int correct, int total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500)),
            Text(
              total == 0
                  ? '– (nincs adat)'
                  : '${pct.toStringAsFixed(1)}%  ($correct/$total)',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : (pct / 100).clamp(0.0, 1.0),
            backgroundColor: const Color(0xFFF1F5F9),
            color: Colors.blueAccent,
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _statBox(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
      ],
    );
  }
}
