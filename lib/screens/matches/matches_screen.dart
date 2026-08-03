import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/statpal_service.dart';
import '../ai/ai_analysis_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final StatpalService _statpalService = StatpalService();
  late Future<Map<String, dynamic>?> _matchesFuture;

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
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final selected =
          DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final difference = selected.difference(today).inDays;

      if (difference == 0) {
        _matchesFuture = _statpalService.getLiveMatches(forceRefresh: true);
      } else if (difference >= -7 && difference <= 7) {
        _matchesFuture = _statpalService.getDailyMatches(difference);
      } else {
        _matchesFuture =
            _statpalService.getDailyMatches(difference > 0 ? 7 : -7);
      }
    });
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
            tooltip: _showOnlyLive ? 'Összes meccs mutatása' : 'Csak élő meccsek',
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
            icon: Icon(_allCollapsed ? Icons.unfold_more : Icons.unfold_less,
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
                    prefixIcon:
                        const Icon(Icons.search, size: 18, color: Colors.grey),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
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
            child: FutureBuilder<Map<String, dynamic>?>(
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
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(
                      child: Text('Nincsenek elérhető mérkőzések.',
                          style: TextStyle(fontSize: 13)));
                }

                final data = snapshot.data!;

                List<dynamic> leaguesList = [];
                try {
                  for (var key in data.keys) {
                    if (data[key] is Map && data[key]['league'] is List) {
                      leaguesList = data[key]['league'];
                      break;
                    }
                  }
                } catch (_) {}

                if (leaguesList.isEmpty && data['league'] is List) {
                  leaguesList = data['league'];
                }

                if (leaguesList.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'Nincsenek elérhető mérkőzések ezen a napon, vagy a Statpal API nem adott vissza adatot.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  );
                }

                List<Map<String, dynamic>> processedLeagues = [];

                for (var leagueGroup in leaguesList) {
                  final leagueName =
                      leagueGroup['name']?.toString() ?? 'Ismeretlen Bajnokság';
                  final leagueId = leagueGroup['id']?.toString();

                  // match lehet lista VAGY egyetlen objektum
                  dynamic rawMatches = leagueGroup['match'];
                  List<dynamic> matches = [];
                  if (rawMatches is List) {
                    matches = rawMatches;
                  } else if (rawMatches is Map) {
                    matches = [rawMatches];
                  }

                  List<dynamic> validMatches = matches.where((match) {
                    if (match is! Map) return false;
                    final status =
                        match['status']?.toString().toUpperCase() ?? '';

                    if (_showOnlyLive) {
                      if (!(status.contains('LIVE') ||
                          status.contains('1H') ||
                          status.contains('2H') ||
                          status == 'HT')) {
                        return false;
                      }
                    }

                    final home =
                        match['home']?['name']?.toString().toLowerCase() ?? '';
                    final away =
                        match['away']?['name']?.toString().toLowerCase() ?? '';
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
                      child: Text('Nincs a szűrésnek megfelelő mérkőzés.',
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
                                if (_collapsedLeagues.contains(leagueName)) {
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
                              final homeTeam =
                                  match['home']?['name']?.toString() ?? 'Hazai';
                              final awayTeam =
                                  match['away']?['name']?.toString() ??
                                      'Vendég';
                              final homeScore = match['home']?['goals'] ??
                                  match['ft']?['home_goals'] ??
                                  '-';
                              final awayScore = match['away']?['goals'] ??
                                  match['ft']?['away_goals'] ??
                                  '-';
                              final status =
                                  match['status']?.toString() ?? 'Kezdés';
                              final timeStr = match['time']?.toString() ?? '';

                              final homeTeamId =
                                  match['home']?['id']?.toString();
                              final awayTeamId =
                                  match['away']?['id']?.toString();

                              return InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AiAnalysisScreen(
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
                                        width: 50,
                                        child: Text(
                                          status == 'FT'
                                              ? 'Vége'
                                              : (status.isEmpty
                                                  ? timeStr
                                                  : status),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: status == 'FT'
                                                ? Colors.grey
                                                : Colors.green,
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
                                                  fontWeight: FontWeight.w500),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 1),
                                            Text(
                                              awayTeam,
                                              style: const TextStyle(
                                                  fontSize: 11.5,
                                                  color: Colors.black54,
                                                  fontWeight: FontWeight.w400),
                                              overflow: TextOverflow.ellipsis,
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
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            '$awayScore',
                                            style: const TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.bold,
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
