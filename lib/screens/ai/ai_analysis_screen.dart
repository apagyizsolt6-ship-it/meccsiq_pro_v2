import 'package:flutter/material.dart';
import '../../services/ai_simulation_service.dart';

class AiAnalysisScreen extends StatefulWidget {
  final String homeTeam;
  final String awayTeam;
  final String leagueName;

  const AiAnalysisScreen({
    super.key,
    required this.homeTeam,
    required this.awayTeam,
    required this.leagueName,
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
    // Lefuttatjuk az 50 000-es Monte Carlo szimulációt a Statpal élő adatok alapján
    final result = await AiSimulationService.runMonteCarloSimulation(
      homeTeam: widget.homeTeam,
      awayTeam: widget.awayTeam,
    );

    // Lekérjük az AI elemzést a kapott eredménnyel
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('AI & Monte Carlo Elemzés', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
                    style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Meccsfejléc Kártya
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            widget.leagueName.toUpperCase(),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.homeTeam,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text('VS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                              ),
                              Expanded(
                                child: Text(
                                  widget.awayTeam,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Monte Carlo Esélyek Kártya
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                'Monte Carlo Esélyek',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              Text(
                                '${_simulationResult.totalSimulations} futtatás',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          _buildProbabilityRow('Hazai győzelem (${widget.homeTeam})', _simulationResult.homeWinProbability, Colors.green),
                          const SizedBox(height: 8),
                          _buildProbabilityRow('Döntetlen', _simulationResult.drawProbability, Colors.orange),
                          const SizedBox(height: 8),
                          _buildProbabilityRow('Vendég győzelem (${widget.awayTeam})', _simulationResult.awayWinProbability, Colors.blue),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatBox('Legvalószínűbb', _simulationResult.mostLikelyScore),
                              _buildStatBox('Hazai Gólátlag', _simulationResult.averageHomeGoals.toStringAsFixed(2)),
                              _buildStatBox('Vendég Gólátlag', _simulationResult.averageAwayGoals.toStringAsFixed(2)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // AI Szakértő Elemzés Kártya
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.psychology, size: 18, color: Colors.blueAccent),
                              SizedBox(width: 6),
                              Text(
                                'AI Szakértői Értékelés',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Text(
                            _aiAnalysisText,
                            style: const TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.4),
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
            Text(label, style: const TextStyle(fontSize: 11.5, color: Colors.black54, fontWeight: FontWeight.w500)),
            Text('${percentage.toStringAsFixed(1)}%', style: TextStyle(fontSize: 11.5, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
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
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }
}
