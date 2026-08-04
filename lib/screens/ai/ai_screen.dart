import 'package:flutter/material.dart';
import '../../services/statpal_service.dart';
import '../../services/ai_simulation_service.dart';
import '../../utils/app_translator.dart';
import 'ai_analysis_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final StatpalService _statpal = StatpalService();
  bool _isLoading = true;
  bool _hideWeakData = true;
  String _filter = 'all'; // all | value | over25 | btts | double

  List<Map<String, dynamic>> _tips = [];
  Set<String> _favoriteTeamIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
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

      for (final m in matches) {
        if (m is! Map) continue;

        final status = (m['status']?.toString() ?? '').toUpperCase();
        // Csak még nem kezdődött vagy élő meccsek
        if (status == 'FT' || status == 'AET' || status == 'FT_PEN') continue;

        final homeId = m['home']?['id']?.toString();
        final awayId = m['away']?['id']?.toString();
        final homeName = AppTranslator.translateTeam(
            m['home']?['name']?.toString() ?? 'Hazai');
        final awayName = AppTranslator.translateTeam(
            m['away']?['name']?.toString() ?? 'Vendég');

        // Szimuláció futtatása
        final sim = await AiSimulationService.runMonteCarloSimulation(
          homeTeam: homeName,
          awayTeam: awayName,
          team1Id: homeId,
          team2Id: awayId,
          leagueId: leagueId,
        );

        if (_hideWeakData && sim.dataQuality == 'weak') continue;

        // Érték számítás (egyszerűsített – a teljes odds később jön)
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
        });
      }
    }

    // Rendezés: kedvencek előre, aztán erősség szerint
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

  List<Map<String, dynamic>> get _filteredTips {
    return _tips.where((t) {
      final sim = t['sim'] as MatchSimulationResult;

      switch (_filter) {
        case 'value':
          // Egyelőre a legerősebb tippeket mutatjuk értéknek
          return t['tipProb'] >= 55;
        case 'over25':
          return sim.over25Probability >= 55;
        case 'btts':
          return sim.bttsYesProbability >= 55;
        case 'double':
          return sim.doubleChance1X >= 70 ||
              sim.doubleChance12 >= 70 ||
              sim.doubleChanceX2 >= 70;
        default:
          return true;
      }
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
          // Szűrők
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('Összes', 'all'),
                  _filterChip('Erős tipp', 'value'),
                  _filterChip('Over 2.5', 'over25'),
                  _filterChip('BTTS', 'btts'),
                  _filterChip('Double Chance', 'double'),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Gyenge adat elrejt',
                        style: TextStyle(fontSize: 12)),
                    selected: _hideWeakData,
                    onSelected: (v) {
                      setState(() => _hideWeakData = v);
                      _loadData();
                    },
                    selectedColor: Colors.blue.shade50,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

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
                : _filteredTips.isEmpty
                    ? const Center(
                        child: Text(
                          'Nincs a szűrésnek megfelelő tipp ma.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filteredTips.length,
                          itemBuilder: (context, index) {
                            final tip = _filteredTips[index];
                            final sim = tip['sim'] as MatchSimulationResult;
                            final isFav = tip['isFavorite'] == true;

                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 10),
                              color: isFav
                                  ? const Color(0xFFFFF8E1)
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              tip['leagueName']
                                                  .toString()
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.blueGrey,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                          if (isFav)
                                            const Icon(Icons.star,
                                                size: 16, color: Colors.amber),
                                          const SizedBox(width: 6),
                                          Text(
                                            tip['time'] ?? '',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${tip['homeTeam']}  vs  ${tip['awayTeam']}',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          _miniStat('1',
                                              sim.homeWinProbability, Colors.green),
                                          _miniStat('X',
                                              sim.drawProbability, Colors.orange),
                                          _miniStat('2',
                                              sim.awayWinProbability, Colors.blue),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _tipLabel(tip['tipSide'],
                                                  tip['tipProb']),
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blueAccent),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Text(
                                            'O2.5 ${sim.over25Probability.toStringAsFixed(0)}%',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.black54),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'BTTS ${sim.bttsYesProbability.toStringAsFixed(0)}%',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.black54),
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
                                              color: sim.dataQuality == 'strong'
                                                  ? Colors.green
                                                  : sim.dataQuality == 'medium'
                                                      ? Colors.orange
                                                      : Colors.redAccent,
                                              fontWeight: FontWeight.w600,
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
                      ),
          ),
        ],
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

  Widget _miniStat(String label, double pct, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: color, fontWeight: FontWeight.bold)),
          Text('${pct.toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _tipLabel(String side, double prob) {
    final p = prob.toStringAsFixed(0);
    if (side == 'home') return 'Hazai $p%';
    if (side == 'away') return 'Vendég $p%';
    return 'Döntetlen $p%';
  }
}
