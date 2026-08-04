import 'package:flutter/material.dart';
import '../../services/ai_simulation_service.dart';

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

    if (mounted) {
      setState(() {
        _simulationResult = result;
        _aiAnalysisText = analysis;
        _isLoading = false;
      });
    }
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
                    'Statpal adatok lekérése és\n50 000 szimuláció futtatása...\n${widget.homeTeam} vs ${widget.awayTeam}',
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
                              _qualityLabel(_simulationResult.dataQuality),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _qualityColor(
                                    _simulationResult.dataQuality),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Monte Carlo 1X2
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
                              Colors.green),
                          const SizedBox(height: 8),
                          _buildProbabilityRow('Döntetlen',
                              _simulationResult.drawProbability, Colors.orange),
                          const SizedBox(height: 8),
                          _buildProbabilityRow(
                              'Vendég győzelem (${widget.awayTeam})',
                              _simulationResult.awayWinProbability,
                              Colors.blue),
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

                  // Over/Under + BTTS
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
                            'Gólpiacok (szimulációból)',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                          ),
                          const Divider(height: 20),
                          _buildProbabilityRow(
                              'Over 2.5 gól',
                              _simulationResult.over25Probability,
                              Colors.purple),
                          const SizedBox(height: 8),
                          _buildProbabilityRow(
                              'Under 2.5 gól',
                              _simulationResult.under25Probability,
                              Colors.blueGrey),
                          const SizedBox(height: 12),
                          _buildProbabilityRow(
                              'BTTS igen (mindkét csapat szerez)',
                              _simulationResult.bttsYesProbability,
                              Colors.teal),
                          const SizedBox(height: 8),
                          _buildProbabilityRow(
                              'BTTS nem',
                              _simulationResult.bttsNoProbability,
                              Colors.brown),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // StatPal valós adatok
                  if (_simulationResult.homeForm != null ||
                      _simulationResult.homePosition != null ||
                      _simulationResult.h2hMatchesUsed > 0)
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
                            if (_simulationResult.homeForm != null ||
                                _simulationResult.awayForm != null)
                              _infoRow(
                                  'Forma (utolsó 5)',
                                  '${_simulationResult.homeForm ?? "–"}  |  ${_simulationResult.awayForm ?? "–"}'),
                            if (_simulationResult.homeGoalsScoredAvg != null)
                              _infoRow(
                                  'Hazai gólátlag',
                                  '${_simulationResult.homeGoalsScoredAvg!.toStringAsFixed(2)} rúgott / ${_simulationResult.homeGoalsConcededAvg?.toStringAsFixed(2) ?? "?"} kapott'),
                            if (_simulationResult.awayGoalsScoredAvg != null)
                              _infoRow(
                                  'Vendég gólátlag',
                                  '${_simulationResult.awayGoalsScoredAvg!.toStringAsFixed(2)} rúgott / ${_simulationResult.awayGoalsConcededAvg?.toStringAsFixed(2) ?? "?"} kapott'),
                            if (_simulationResult.h2hMatchesUsed > 0) ...[
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
                ],
              ),
            ),
    );
  }

  Widget _buildProbabilityRow(String label, double percentage, Color color) {
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
