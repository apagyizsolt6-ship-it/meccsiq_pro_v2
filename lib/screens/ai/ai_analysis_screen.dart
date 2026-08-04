import 'package:flutter/material.dart';
import '../../services/ai_simulation_service.dart';
import '../../services/statpal_service.dart';

class AiAnalysisScreen extends StatefulWidget {
  final String homeTeam;
  final String awayTeam;
  final String leagueName;
  final String? team1Id;
  final String? team2Id;
  final String? leagueId;

  const AiAnalysisScreen({
    super.key,
    required this.homeTeam,
    required this.awayTeam,
    required this.leagueName,
    this.team1Id,
    this.team2Id,
    this.leagueId,
  });

  @override
  State<AiAnalysisScreen> createState() => _AiAnalysisScreenState();
}

class _AiAnalysisScreenState extends State<AiAnalysisScreen> {
  bool _isLoading = true;
  late MatchSimulationResult _simulationResult;
  String _aiAnalysisText = '';

  // Értékjelzés
  double? _homeEdge;
  double? _drawEdge;
  double? _awayEdge;
  String? _bestValueSide; // 'home' | 'draw' | 'away' | null
  double? _bestValueEdge;

  @override
  void initState() {
    super.initState();
    _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    final result = await AiSimulationService.runMonteCarloSimulation(
      homeTeam: widget.homeTeam,
      awayTeam: widget.awayTeam,
      team1Id: widget.team1Id,
      team2Id: widget.team2Id,
      leagueId: widget.leagueId,
    );

    final analysis = await AiSimulationService.getAiMatchAnalysis(
      homeTeam: widget.homeTeam,
      awayTeam: widget.awayTeam,
      simulation: result,
    );

    // Odds + érték számítás
    await _calculateValue(result);

    if (mounted) {
      setState(() {
        _simulationResult = result;
        _aiAnalysisText = analysis;
        _isLoading = false;
      });
    }
  }

  Future<void> _calculateValue(MatchSimulationResult sim) async {
    if (widget.leagueId == null || widget.leagueId!.isEmpty) return;

    try {
      final oddsData =
          await StatpalService().getPrematchOdds(widget.leagueId!);
      if (oddsData == null) return;

      final prematch = oddsData['prematch_odds'];
      if (prematch == null) return;

      final league = prematch['league'];
      if (league == null) return;

      final matches = league['match'];
      if (matches is! List) return;

      Map? targetMatch;
      for (final m in matches) {
        if (m is! Map) continue;
        final homeId = m['home']?['id']?.toString();
        final awayId = m['away']?['id']?.toString();
        final homeName = (m['home']?['name']?.toString() ?? '').toLowerCase();
        final awayName = (m['away']?['name']?.toString() ?? '').toLowerCase();

        final matchById = (widget.team1Id != null &&
                widget.team2Id != null &&
                homeId == widget.team1Id &&
                awayId == widget.team2Id);

        final matchByName = homeName.contains(widget.homeTeam.toLowerCase()) ||
            widget.homeTeam.toLowerCase().contains(homeName);

        if (matchById || matchByName) {
          targetMatch = m;
          break;
        }
      }

      if (targetMatch == null) return;

      final oddsList = targetMatch['odds'];
      if (oddsList is! List) return;

      Map? oneXTwo;
      for (final o in oddsList) {
        if (o is Map && (o['name']?.toString().toLowerCase() == '1x2')) {
          oneXTwo = o;
          break;
        }
      }
      if (oneXTwo == null) return;

      final bookmakers = oneXTwo['bookmaker'];
      if (bookmakers is! List || bookmakers.isEmpty) return;

      // Az első bookmaker oddsait használjuk
      final firstBook = bookmakers.first;
      if (firstBook is! Map) return;

      final oddItems = firstBook['odd'];
      if (oddItems is! List) return;

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

      if (homeOdds == null || drawOdds == null || awayOdds == null) return;

      // Implied probability (egyszerű, margin nélkül)
      final homeImplied = 100 / homeOdds;
      final drawImplied = 100 / drawOdds;
      final awayImplied = 100 / awayOdds;

      final homeEdge = sim.homeWinProbability - homeImplied;
      final drawEdge = sim.drawProbability - drawImplied;
      final awayEdge = sim.awayWinProbability - awayImplied;

      _homeEdge = homeEdge;
      _drawEdge = drawEdge;
      _awayEdge = awayEdge;

      // Legjobb érték keresése (min. +5% edge)
      double best = -100;
      String? side;
      if (homeEdge > best && homeEdge >= 5.0) {
        best = homeEdge;
        side = 'home';
      }
      if (drawEdge > best && drawEdge >= 5.0) {
        best = drawEdge;
        side = 'draw';
      }
      if (awayEdge > best && awayEdge >= 5.0) {
        best = awayEdge;
        side = 'away';
      }

      _bestValueSide = side;
      _bestValueEdge = side != null ? best : null;
    } catch (_) {}
  }

  Color _qualityColor(String q) {
    if (q == 'strong') return Colors.green;
    if (q == 'medium') return Colors.orange;
    return Colors.redAccent;
  }

  String _qualityLabel(String q) {
    if (q == 'strong') return 'Erős adat';
    if (q == 'medium') return 'Közepes adat';
    return 'Gyenge adat';
  }

  Widget _buildFormCircles(String? form) {
    if (form == null || form.isEmpty) {
      return const Text('–', style: TextStyle(color: Colors.grey));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: form.toUpperCase().split('').map((c) {
        Color bg;
        if (c == 'W') {
          bg = Colors.green;
        } else if (c == 'D') {
          bg = Colors.orange;
        } else if (c == 'L') {
          bg = Colors.redAccent;
        } else {
          bg = Colors.grey;
        }

        return Container(
          width: 22,
          height: 22,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              c,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('AI & Monte Carlo Elemzés',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.blueAccent),
                  const SizedBox(height: 16),
                  Text(
                    'Statpal adatok + odds lekérése\nés 50 000 szimuláció...\n${widget.homeTeam} vs ${widget.awayTeam}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Fejléc
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            widget.leagueName.toUpperCase(),
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.homeTeam,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text('VS',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey)),
                              ),
                              Expanded(
                                child: Text(
                                  widget.awayTeam,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _qualityColor(
                                          _simulationResult.dataQuality)
                                      .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _qualityLabel(
                                      _simulationResult.dataQuality),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _qualityColor(
                                        _simulationResult.dataQuality),
                                  ),
                                ),
                              ),
                              if (_bestValueSide != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'ÉRTÉK +${_bestValueEdge!.toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Monte Carlo 1X2 + érték
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Monte Carlo Esélyek (1X2)',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87),
                              ),
                              Text(
                                '${_simulationResult.totalSimulations} futtatás',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          _buildProbabilityRow(
                            'Hazai győzelem (${widget.homeTeam})',
                            _simulationResult.homeWinProbability,
                            Colors.green,
                            edge: _homeEdge,
                          ),
                          const SizedBox(height: 8),
                          _buildProbabilityRow(
                            'Döntetlen',
                            _simulationResult.drawProbability,
                            Colors.orange,
                            edge: _drawEdge,
                          ),
                          const SizedBox(height: 8),
                          _buildProbabilityRow(
                            'Vendég győzelem (${widget.awayTeam})',
                            _simulationResult.awayWinProbability,
                            Colors.blue,
                            edge: _awayEdge,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatBox('Legvalószínűbb',
                                  _simulationResult.mostLikelyScore),
                              _buildStatBox(
                                  'Hazai xG',
                                  _simulationResult.averageHomeGoals
                                      .toStringAsFixed(2)),
                              _buildStatBox(
                                  'Vendég xG',
                                  _simulationResult.averageAwayGoals
                                      .toStringAsFixed(2)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Gólpiacok
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gólpiacok',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                          ),
                          const Divider(height: 20),
                          _buildProbabilityRow('Over 1.5 gól',
                              _simulationResult.over15Probability, Colors.indigo),
                          const SizedBox(height: 6),
                          _buildProbabilityRow('Under 1.5 gól',
                              _simulationResult.under15Probability, Colors.blueGrey),
                          const SizedBox(height: 10),
                          _buildProbabilityRow('Over 2.5 gól',
                              _simulationResult.over25Probability, Colors.purple),
                          const SizedBox(height: 6),
                          _buildProbabilityRow('Under 2.5 gól',
                              _simulationResult.under25Probability, Colors.blueGrey),
                          const SizedBox(height: 10),
                          _buildProbabilityRow('Over 3.5 gól',
                              _simulationResult.over35Probability, Colors.deepPurple),
                          const SizedBox(height: 6),
                          _buildProbabilityRow('Under 3.5 gól',
                              _simulationResult.under35Probability, Colors.blueGrey),
                          const SizedBox(height: 14),
                          _buildProbabilityRow(
                              'BTTS igen',
                              _simulationResult.bttsYesProbability,
                              Colors.teal),
                          const SizedBox(height: 6),
                          _buildProbabilityRow(
                              'BTTS nem',
                              _simulationResult.bttsNoProbability,
                              Colors.brown),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Double Chance + Top scores
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Double Chance & Pontos eredmény',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                          ),
                          const Divider(height: 20),
                          _buildProbabilityRow('1X (Hazai vagy Döntetlen)',
                              _simulationResult.doubleChance1X, Colors.green),
                          const SizedBox(height: 6),
                          _buildProbabilityRow('12 (Hazai vagy Vendég)',
                              _simulationResult.doubleChance12, Colors.blueGrey),
                          const SizedBox(height: 6),
                          _buildProbabilityRow('X2 (Döntetlen vagy Vendég)',
                              _simulationResult.doubleChanceX2, Colors.blue),
                          const SizedBox(height: 16),
                          const Text(
                            'Top 5 legvalószínűbb eredmény',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54),
                          ),
                          const SizedBox(height: 8),
                          ..._simulationResult.topScores.map((item) {
                            final score = item['score'] as String;
                            final pct = (item['probability'] as double)
                                .toStringAsFixed(1);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 50,
                                    child: Text(
                                      score,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13),
                                    ),
                                  ),
                                  Expanded(
                                    child: LinearProgressIndicator(
                                      value: (item['probability'] as double) /
                                          100,
                                      backgroundColor:
                                          const Color(0xFFF1F5F9),
                                      color: Colors.blueAccent,
                                      minHeight: 6,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('$pct%',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // StatPal valós adatok + Forma vizualizáció
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'StatPal valós adatok',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                          ),
                          const Divider(height: 20),
                          if (_simulationResult.homePosition != null ||
                              _simulationResult.awayPosition != null)
                            _infoRow(
                                'Tabella',
                                '${_simulationResult.homePosition ?? "?"}. – ${_simulationResult.awayPosition ?? "?"}. hely'),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const SizedBox(
                                width: 110,
                                child: Text(
                                  'Forma (Hazai)',
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              _buildFormCircles(_simulationResult.homeForm),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const SizedBox(
                                width: 110,
                                child: Text(
                                  'Forma (Vendég)',
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              _buildFormCircles(_simulationResult.awayForm),
                            ],
                          ),
                          if (_simulationResult.homeGoalsScoredAvg != null) ...[
                            const SizedBox(height: 8),
                            _infoRow(
                                'Hazai gólátlag',
                                '${_simulationResult.homeGoalsScoredAvg!.toStringAsFixed(2)} rúgott / ${_simulationResult.homeGoalsConcededAvg?.toStringAsFixed(2) ?? "?"} kapott'),
                          ],
                          if (_simulationResult.awayGoalsScoredAvg != null)
                            _infoRow(
                                'Vendég gólátlag',
                                '${_simulationResult.awayGoalsScoredAvg!.toStringAsFixed(2)} rúgott / ${_simulationResult.awayGoalsConcededAvg?.toStringAsFixed(2) ?? "?"} kapott'),
                          if (_simulationResult.h2hMatchesUsed > 0) ...[
                            const SizedBox(height: 6),
                            _infoRow(
                              'H2H meccsek',
                              '\( {_simulationResult.h2hMatchesUsed} db \){_simulationResult.usedWeightedH2h ? " (súlyozott)" : ""}',
                            ),
                            if (_simulationResult.recentScores.isNotEmpty)
                              _infoRow(
                                'Utolsó eredmények',
                                _simulationResult.recentScores.join('  •  '),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // AI szöveg
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.psychology,
                                  size: 18, color: Colors.blueAccent),
                              SizedBox(width: 6),
                              Text(
                                'AI Szakértői Értékelés',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Text(
                            _aiAnalysisText,
                            style: const TextStyle(
                                fontSize: 12.5,
                                color: Colors.black87,
                                height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildProbabilityRow(String label, double percentage, Color color,
      {double? edge}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 11.5,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500)),
            ),
            if (edge != null && edge >= 5.0)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '+${edge.toStringAsFixed(1)}%',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                ),
              ),
            Text('${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                    fontSize: 11.5, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (percentage / 100).clamp(0.0, 1.0),
            backgroundColor: const Color(0xFFF1F5F9),
            color: color,
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 11.5,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 11.5,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
