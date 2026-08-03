import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/statpal_service.dart';
import '../../utils/app_translator.dart';
import '../ai/ai_analysis_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final StatpalService _statpalService = StatpalService();
  late Future<List<Map<String, dynamic>>> _matchesFuture;

  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  bool _showOnlyLive = false;
  final Set<String> _collapsedLeagues = {};
  bool _allCollapsed = true;

  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _loadMatches() {
    setState(() {
      _matchesFuture = _fetchAllMatches();
    });
  }

  Future<List<Map<String, dynamic>>> _fetchAllMatches() async {
    final List<Map<String, dynamic>> combined = [];
    final Set<String> seenLeagueIds = {};

    final selected =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

    // 1) Prioritásos ligák – csak a kiválasztott nap
    try {
      final priority = await _statpalService.getPriorityLeagueMatches(
        filterDate: selected,
      );
      for (final lg in priority) {
        final id = lg['id']?.toString() ?? '';
        if (id.isNotEmpty) seenLeagueIds.add(id);
        combined.add(lg);
      }
    } catch (_) {}

    // 2) Globális live / daily
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final difference = selected.difference(today).inDays;

      Map<String, dynamic>? globalData;
      if (difference == 0) {
        globalData =
            await _statpalService.getLiveMatches(forceRefresh: true);
      } else if (difference >= -7 && difference <= 7) {
        globalData = await _statpalService.getDailyMatches(difference);
      } else {
        globalData = await _statpalService
            .getDailyMatches(difference > 0 ? 7 : -7);
      }

      if (globalData != null) {
        List<dynamic> leaguesList = [];
        for (var key in globalData.keys) {
          if (globalData[key] is Map &&
              globalData[key]['league'] is List) {
            leaguesList = globalData[key]['league'];
            break;
          }
        }
        if (leaguesList.isEmpty && globalData['league'] is List) {
          leaguesList = globalData['league'];
        }

        for (final leagueGroup in leaguesList) {
          if (leagueGroup is! Map) continue;

          final leagueId = leagueGroup['id']?.toString() ?? '';
          if (leagueId.isNotEmpty && seenLeagueIds.contains(leagueId)) {
            continue;
          }

          final country = leagueGroup['country']?.toString() ?? '';
          final rawName =
              leagueGroup['name']?.toString() ?? 'Ismeretlen bajnokság';

          final rawFull = country.isNotEmpty && !rawName.contains(':')
              ? '$country: $rawName'
              : rawName;

          var leagueName = AppTranslator.translateLeague(rawFull);

          // Biztonsági háló – rossz ID ne kapjon top nevet
          if (leagueName == 'Anglia – Premier League' &&
              leagueId != '3037') {
            leagueName = country.isNotEmpty
                ? '${AppTranslator.translateCountry(country)} – Premier Liga'
                : 'Premier Liga';
          }
          if (leagueName == 'Spanyolország – La Liga' &&
              leagueId != '3232') {
            leagueName = country.isNotEmpty
                ? '${AppTranslator.translateCountry(country)} – $rawName'
                : rawName;
          }
          if (leagueName == 'Spanyolország – La Liga 2' &&
              leagueId != '3231') {
            leagueName = country.isNotEmpty
                ? '${AppTranslator.translateCountry(country)} – Segunda'
                : 'Segunda';
          }
          if (leagueName == 'UEFA – Bajnokok Ligája' &&
              leagueId != '2838') {
            leagueName = country.isNotEmpty
                ? '${AppTranslator.translateCountry(country)} – $rawName'
                : rawName;
          }
          if (leagueName == 'UEFA – Európa Liga' && leagueId != '2840') {
            leagueName = country.isNotEmpty
                ? '${AppTranslator.translateCountry(country)} – $rawName'
                : rawName;
          }
          if (leagueName == 'Olaszország – Serie A' &&
              leagueId != '3102') {
            leagueName = country.isNotEmpty
                ? '${AppTranslator.translateCountry(country)} – $rawName'
                : rawName;
          }
          if (leagueName == 'Németország – Bundesliga' &&
              leagueId != '3062') {
            leagueName = country.isNotEmpty
                ? '${AppTranslator.translateCountry(country)} – $rawName'
                : rawName;
          }
          if (leagueName == 'Franciaország – Ligue 1' &&
              leagueId != '3054') {
            leagueName = country.isNotEmpty
                ? '${AppTranslator.translateCountry(country)} – $rawName'
                : rawName;
          }

          dynamic rawMatches = leagueGroup['match'];
          List<dynamic> matches = [];
          if (rawMatches is List) {
            matches = List.from(rawMatches);
          } else if (rawMatches is Map) {
            matches = [rawMatches];
          }
          if (matches.isEmpty) continue;

          combined.add({
            'name': leagueName,
            'id': leagueId,
            'matches': matches,
          });
        }
      }
    } catch (_) {}

    return combined;
  }

  Future<void> _handleRefresh() async {
    _loadMatches();
    await _matchesFuture;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2028, 12, 31),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _loadMatches();
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        _searchQuery = query.toLowerCase();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    const monthsHu = [
      '',
      'január',
      'február',
      'március',
      'április',
      'május',
      'június',
      'július',
      'augusztus',
      'szeptember',
      'október',
      'november',
      'december'
    ];
    final dateString =
        '${_selectedDate.year}. ${monthsHu[_selectedDate.month]} ${_selectedDate.day}.';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Statpal Foci Eredmények',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _showOnlyLive ? Icons.live_tv : Icons.tv_off,
              size: 20,
              color: _showOnlyLive ? Colors.red : Colors.grey,
            ),
            tooltip:
                _showOnlyLive ? 'Összes meccs mutatása' : 'Csak élő meccsek',
            onPressed: () {
              setState(() {
                _showOnlyLive = !_showOnlyLive;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Frissítés',
            onPressed: _handleRefresh,
          ),
          IconButton(
            icon: Icon(
                _allCollapsed ? Icons.unfold_more : Icons.unfold_less,
                size: 20),
            tooltip: _allCollapsed ? 'Mindet kinyit' : 'Mindet összecsuk',
            onPressed: () {
              setState(() {
                _allCollapsed = !_allCollapsed;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today, size: 20),
            onPressed: () => _selectDate(context),
            tooltip: 'Dátum választása',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: () => _selectDate(context),
                      icon: const Icon(Icons.calendar_month,
                          size: 16, color: Colors.blueAccent),
                      label: Text(
                        dateString,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  onChanged: _onSearchChanged,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Keresés csapat vagy bajnokság szerint...',
                    hintStyle:
                        const TextStyle(fontSize: 12, color: Colors.grey),
                    prefixIcon: const Icon(Icons.search,
                        size: 18, color: Colors.grey),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 0, horizontal: 12),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _matchesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Hiba az adatok betöltése közben:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'Nincsenek elérhető mérkőzések ezen a napon.',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  );
                }

                final leagues = snapshot.data!;
                final List<Map<String, dynamic>> processedLeagues = [];

                for (final leagueData in leagues) {
                  final leagueName =
                      leagueData['name']?.toString() ?? 'Ismeretlen';
                  final leagueId = leagueData['id']?.toString();
                  final rawMatches = leagueData['matches'];

                  List<dynamic> matches = [];
                  if (rawMatches is List) matches = rawMatches;

                  final validMatches = matches.where((match) {
                    if (match is! Map) return false;
                    final status =
                        match['status']?.toString().toUpperCase() ?? '';

                    if (_showOnlyLive) {
                      if (!(status.contains('LIVE') ||
                          status.contains('1H') ||
                          status.contains('2H') ||
                          status == 'HT' ||
                          status.contains('IN_PLAY'))) {
                        return false;
                      }
                    }

                    final home = AppTranslator.translateTeam(
                            match['home']?['name']?.toString() ?? '')
                        .toLowerCase();
                    final away = AppTranslator.translateTeam(
                            match['away']?['name']?.toString() ?? '')
                        .toLowerCase();
                    final league = leagueName.toLowerCase();

                    return home.contains(_searchQuery) ||
                        away.contains(_searchQuery) ||
                        league.contains(_searchQuery);
                  }).toList();

                  if (validMatches.isNotEmpty) {
                    processedLeagues.add({
                      'name': leagueName,
                      'id': leagueId,
                      'matches': validMatches,
                    });
                  }
                }

                if (processedLeagues.isEmpty) {
                  return const Center(
                      child: Text(
                          'Nincs a szűrésnek megfelelő mérkőzés ezen a napon.',
                          style: TextStyle(fontSize: 13)));
                }

                return RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: processedLeagues.length,
                    itemBuilder: (context, leagueIndex) {
                      final leagueData = processedLeagues[leagueIndex];
                      final leagueName = leagueData['name'] as String;
                      final leagueId = leagueData['id'] as String?;
                      final leagueMatches =
                          leagueData['matches'] as List<dynamic>;

                      final isCollapsed = _allCollapsed
                          ? !_collapsedLeagues.contains(leagueName)
                          : _collapsedLeagues.contains(leagueName);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                if (_collapsedLeagues
                                    .contains(leagueName)) {
                                  _collapsedLeagues.remove(leagueName);
                                } else {
                                  _collapsedLeagues.add(leagueName);
                                }
                              });
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              color: const Color(0xFFE2E8F0),
                              child: Row(
                                children: [
                                  const Icon(Icons.sports_soccer,
                                      size: 13, color: Colors.black54),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      leagueName.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    isCollapsed
                                        ? Icons.expand_more
                                        : Icons.expand_less,
                                    size: 16,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (!isCollapsed)
                            ...leagueMatches.map((match) {
                              final homeRaw =
                                  match['home']?['name']?.toString() ??
                                      'Hazai';
                              final awayRaw =
                                  match['away']?['name']?.toString() ??
                                      'Vendég';
                              final homeTeam =
                                  AppTranslator.translateTeam(homeRaw);
                              final awayTeam =
                                  AppTranslator.translateTeam(awayRaw);

                              final homeScore = match['home']?['goals'] ??
                                  match['home']?['score'] ??
                                  match['ft']?['home_goals'] ??
                                  '-';
                              final awayScore = match['away']?['goals'] ??
                                  match['away']?['score'] ??
                                  match['ft']?['away_goals'] ??
                                  '-';

                              final statusRaw =
                                  match['status']?.toString() ?? '';
                              final statusUpper = statusRaw.toUpperCase();
                              final isFinished = statusUpper == 'FT' ||
                                  statusUpper == 'AET' ||
                                  statusUpper == 'FT_PEN';
                              final isNotStarted = statusUpper == 'NS' ||
                                  statusUpper == 'NOT STARTED' ||
                                  statusUpper.isEmpty;

                              String statusDisplay;
                              if (isFinished) {
                                statusDisplay = 'Vége';
                              } else if (isNotStarted) {
                                statusDisplay =
                                    AppTranslator.formatMatchTime(
                                  date: match['date']?.toString(),
                                  time: match['time']?.toString(),
                                  selectedDate: _selectedDate,
                                );
                              } else {
                                statusDisplay =
                                    AppTranslator.translateStatus(
                                        statusRaw);
                              }

                              final homeTeamId =
                                  match['home']?['id']?.toString();
                              final awayTeamId =
                                  match['away']?['id']?.toString();

                              return InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AiAnalysisScreen(
                                        homeTeam: homeTeam,
                                        awayTeam: awayTeam,
                                        leagueName: leagueName,
                                        team1Id: homeTeamId,
                                        team2Id: awayTeamId,
                                        leagueId: leagueId,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    border: Border(
                                        bottom: BorderSide(
                                            color: Color(0xFFF1F5F9),
                                            width: 1)),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 58,
                                        child: Text(
                                          statusDisplay,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isFinished
                                                ? Colors.grey
                                                : (isNotStarted
                                                    ? Colors.blueGrey
                                                    : Colors.green),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              homeTeam,
                                              style: const TextStyle(
                                                  fontSize: 11.5,
                                                  color: Colors.black87,
                                                  fontWeight:
                                                      FontWeight.w500),
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 1),
                                            Text(
                                              awayTeam,
                                              style: const TextStyle(
                                                  fontSize: 11.5,
                                                  color: Colors.black54,
                                                  fontWeight:
                                                      FontWeight.w400),
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        child: Icon(Icons.psychology,
                                            size: 16,
                                            color: Colors.blueAccent),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '$homeScore',
                                            style: const TextStyle(
                                                fontSize: 11.5,
                                                fontWeight:
                                                    FontWeight.bold,
                                                color: Colors.black87),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            '$awayScore',
                                            style: const TextStyle(
                                                fontSize: 11.5,
                                                fontWeight:
                                                    FontWeight.bold,
                                                color: Colors.black87),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
