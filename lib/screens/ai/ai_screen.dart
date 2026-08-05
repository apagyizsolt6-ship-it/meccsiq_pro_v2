import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/statpal_service.dart';
import '../../services/ai_simulation_service.dart';
import '../../utils/app_translator.dart';
import '../../utils/odds_value_calculator.dart';
import 'ai_analysis_screen.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> with SingleTickerProviderStateMixin {
  final StatpalService _statpal = StatpalService();
  late TabController _tabController;

  bool _isLoading = true;
  bool _hideWeakData = true;
  String _filter = 'all';

  List<Map<String, dynamic>> _tips = [];
  Set<String> _favoriteTeamIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    _favoriteTeamIds = (prefs.getStringList('favorite_team_ids') ?? []).toSet();

    final today = DateTime.now();
    final priority = await _statpal.getPriorityLeagueMatches(filterDate: today);

    final List<Map<String, dynamic>> collected = [];

    for (final league in priority) {
      final leagueName = league['name']?.toString() ?? '';
      final leagueId = league['id']?.toString();
      final matches = league['matches'] as List? ?? [];

      Map<String, Map<String, double>> leagueOdds = {};
      if (leagueId != null && leagueId.isNotEmpty) {
        try {
          final oddsData = await _statpal.getPrematchOdds(leagueId);
          leagueOdds = OddsValueCalculator.parseLeagueOdds(oddsData);
        } catch (_) {}
      }

      for (final m in matches) {
        if (m is! Map) continue;

        final status = (m['status']?.toString() ?? '').toUpperCase();
        if (status == 'FT' || status == 'AET' || status == 'FT_PEN') continue;

        final homeId = m['home']?['id']?.toString();
        final awayId = m['away']?['id']?.toString();
        final homeName = AppTranslator.translateTeam(
            m['home']?['name']?.toString() ?? 'Hazai');
        final awayName = AppTranslator.translateTeam(
            m['away']?['name']?.toString() ?? 'Vendég');

        final sim = await AiSimulationService.runMonteCarloSimulation(
          homeTeam: homeName,
          awayTeam: awayName,
          team1Id: homeId,
          team2Id: awayId,
          leagueId: leagueId,
        );

        if (_hideWeakData && sim.dataQuality == 'weak') continue;

        final maxProb = [
          sim.homeWinProbability,
          sim.drawProbability,
          sim.awayWinProbability
        ].reduce((a, b) => a > b ? a : b);

        String tipSide = 'draw';
        double tipProb = sim.drawProbability;
        if (sim.homeWinProbability >= sim.awayWinProbability &&
            sim.homeWinProbability >= sim.drawProbability) {
          tipSide = 'home';
          tipProb = sim.homeWinProbability;
        } else if (sim.awayWinProbability >= sim.homeWinProbability &&
            sim.awayWinProbability >= sim.drawProbability) {
          tipSide = 'away';
          tipProb = sim.awayWinProbability;
        }

        final odds = OddsValueCalculator.findOdds(
          leagueOdds,
          homeId: homeId,
          awayId: awayId,
          homeName: homeName,
          awayName: awayName,
        );
        final value = OddsValueCalculator.calculateEdge(
          odds: odds,
          homeWinProbability: sim.homeWinProbability,
          drawProbability: sim.drawProbability,
          awayWinProbability: sim.awayWinProbability,
        );

        collected.add({
          'leagueName': leagueName,
          'leagueId': leagueId,
          'homeTeam': homeName,
          'awayTeam': awayName,
          'homeId': homeId,
          'awayId': awayId,
          'time': m['time']?.toString() ?? '',
          'sim': sim,
          'tipSide': tipSide,
          'tipProb': tipProb,
          'isFavorite': (homeId != null && _favoriteTeamIds.contains(homeId)) ||
              (awayId != null && _favoriteTeamIds.contains(awayId)),
          'maxProb': maxProb,
          'value': value,
          'dataQuality': sim.dataQuality,
        });
      }
    }

    collected.sort((a, b) {
      if (a['isFavorite'] == true && b['isFavorite'] != true) return -1;
      if (b['isFavorite'] == true && a['isFavorite'] != true) return 1;
      return (b['maxProb'] as double).compareTo(a['maxProb'] as double);
    });

    if (mounted) {
      setState(() {
        _tips = collected;
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _valueTips {
    return _tips.where((t) {
      final value = t['value'] as OddsValueResult?;
      if (value != null && value.hasOdds) {
        return value.hasValue; // csak ahol van valódi value
      }
      return t['tipProb'] >= 58;
    }).toList();
  }

  List<Map<String, dynamic>> get _ensembleTips {
    // Egyelőre a legstabilabb tippeket mutatjuk (később jön a valódi ensemble logika)
    return _tips.where((t) {
      final sim = t['sim'] as MatchSimulationResult;
      return t['tipProb'] >= 55 && sim.dataQuality != 'weak';
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('AI Tippek',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Value Motor / Ensemble fülek
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(22),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: const Color(0xFF0D9488), // zöldes teal
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.black54,
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Value Motor'),
                  Tab(text: 'Ensemble'),
                ],
              ),
            ),
          ),

          // Szűrők
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('Összes', 'all'),
                  _filterChip('Erős value', 'value'),
                  _filterChip('Over 2.5', 'over25'),
                  _filterChip('BTTS', 'btts'),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Gyenge adat elrejt',
                        style: TextStyle(fontSize: 12)),
                    selected: _hideWeakData,
                    onSelected: (v) {
                      setState(() => _hideWeakData = v);
                      _loadData();
                    },
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Tartalom
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('AI tippek generálása...',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTipsList(_valueTips, isValueMode: true),
                      _buildTipsList(_ensembleTips, isValueMode: false),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsList(List<Map<String, dynamic>> tips, {required bool isValueMode}) {
    if (tips.isEmpty) {
      return const Center(
        child: Text(
          'Nincs a szűrésnek megfelelő tipp.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: tips.length,
        itemBuilder: (context, index) {
          final tip = tips[index];
          final sim = tip['sim'] as MatchSimulationResult;
          final isFav = tip['isFavorite'] == true;
          final value = tip['value'] as OddsValueResult?;

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 10),
            color: isFav ? const Color(0xFFFFF8E1) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AiAnalysisScreen(
                      homeTeam: tip['homeTeam'],
                      awayTeam: tip['awayTeam'],
                      leagueName: tip['leagueName'],
                      team1Id: tip['homeId'],
                      team2Id: tip['awayId'],
                      leagueId: tip['leagueId'],
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Liga + idő
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tip['leagueName'].toString().toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.blueGrey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isFav)
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 6),
                        Text(
                          tip['time'] ?? '',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Csapatok + Badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '${tip['homeTeam']} vs ${tip['awayTeam']}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isValueMode && value?.hasValue == true)
                          Text(
                            '+${value!.bestEdge!.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF16A34A),
                            ),
                          )
                        else if (!isValueMode)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'KONSZENZUS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7C3AED),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 1 X 2
                    Row(
                      children: [
                        _probBox('1', sim.homeWinProbability, Colors.green),
                        const SizedBox(width: 8),
                        _probBox('X', sim.drawProbability, Colors.orange),
                        const SizedBox(width: 8),
                        _probBox('2', sim.awayWinProbability, Colors.blue),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Alsó infók
                    Row(
                      children: [
                        Text(
                          'O2.5 ${sim.over25Probability.toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'BTTS ${sim.bttsYesProbability.toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                        const Spacer(),
                        Text(
                          sim.dataQuality == 'strong'
                              ? 'Erős adat'
                              : sim.dataQuality == 'medium'
                                  ? 'Közepes'
                                  : 'Gyenge',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: sim.dataQuality == 'strong'
                                ? Colors.green
                                : sim.dataQuality == 'medium'
                                    ? Colors.orange
                                    : Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _probBox(String label, double pct, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label ${pct.toStringAsFixed(0)}%',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
        selectedColor: Colors.blue.shade50,
      ),
    );
  }
}
