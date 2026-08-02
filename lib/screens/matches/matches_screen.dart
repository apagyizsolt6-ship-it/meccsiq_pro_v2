import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/sports_db_service.dart';

// ==========================================
// KÖZPONTI FORDÍTÓ OSZTÁLY (AppTranslator)
// ==========================================
class AppTranslator {
  // Mérkőzés státuszok központi fordítása
  static String translateStatus(String status) {
    final s = status.toUpperCase().trim();
    if (s == 'FT' || s == 'AET' || s == 'FT_PEN') return 'Vége';
    if (s == 'HT') return 'Félidő';
    if (s == 'NS') return 'Kezdésre vár';
    if (s == '1H') return '1. félidő';
    if (s == '2H') return '2. félidő';
    if (s == 'ET') return 'Hosszabbítás';
    if (s == 'PEN') return 'Büntetők';
    if (s.contains('LIVE') || s.contains('IN_PLAY')) return 'Élő';
    return s;
  }

  // Bajnokságnevek központi fordítása és szépítése
  static String translateLeague(String leagueName) {
    String l = leagueName.trim();
    
    final translations = {
      'International Friendlies': 'Nemzetközi Felkészülési Mérkőzések',
      'Swedish Allsvenskan': 'Svéd 1. osztály (Allsvenskan)',
      'Norwegian Eliteserien': 'Norvég 1. osztály (Eliteserien)',
      'Argentinian Primera Division': 'Argentin 1. osztály',
      'Argentinian Primera B Nacional': 'Argentin 2. osztály',
      'Finnish Veikkausliiga': 'Finn 1. osztály (Veikkausliiga)',
      'Canadian Premier League': 'Kanadai Premier Liga',
      'Icelandic Úrvalsdeild Karla': 'Izlandi 1. osztály',
      'Chilean Primera Division': 'Chilei 1. osztály',
      'South Korean K League 1': 'Dél-koreai 1. osztály',
      'South Korean K League 2': 'Dél-koreai 2. osztály',
      'Algerian Ligue 1': 'Algériai 1. osztály',
      'MLS Next Pro': 'USA - MLS Next Pro',
      'American Major League Soccer': 'USA - MLS',
    };

    if (translations.containsKey(l)) {
      return translations[l]!;
    }

    l = l.replaceAll('Premier Division', 'Premier Liga');
    l = l.replaceAll('First Division', '1. Osztály');
    l = l.replaceAll('Second Division', '2. Osztály');
    l = l.replaceAll('Division 1', '1. Divízió');
    
    return l;
  }
}

// ==========================================
// KÉPERNYŐ
// ==========================================
class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final SportsDbService _sportsDbService = SportsDbService();
  late Future<Map<String, dynamic>?> _matchesFuture;
  
  DateTime _selectedDate = DateTime(2026, 6, 6);
  
  String _searchQuery = '';
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
    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    setState(() {
      _matchesFuture = _sportsDbService.getMatchesForDate(formattedDate);
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
      '', 'január', 'február', 'március', 'április', 'május', 'június',
      'július', 'augusztus', 'szeptember', 'október', 'november', 'december'
    ];
    final dateString = '${_selectedDate.year}. ${monthsHu[_selectedDate.month]} ${_selectedDate.day}.';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Élő Foci Eredmények', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_allCollapsed ? Icons.unfold_more : Icons.unfold_less, size: 20),
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
                      icon: const Icon(Icons.calendar_month, size: 16, color: Colors.blueAccent),
                      label: Text(
                        dateString,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
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
                    hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
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
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(child: Text('Nincsenek elérhető mérkőzések.', style: TextStyle(fontSize: 13)));
                }

                final data = snapshot.data!;
                final allEvents = data['events'] as List<dynamic>? ?? [];

                final matches = allEvents.where((match) {
                  final sport = match['strSport']?.toString().toLowerCase() ?? '';
                  return sport == 'soccer' || (sport.contains('football') && !sport.contains('american'));
                }).toList();

                final filteredMatches = matches.where((match) {
                  final home = match['strHomeTeam']?.toString().toLowerCase() ?? '';
                  final away = match['strAwayTeam']?.toString().toLowerCase() ?? '';
                  final rawLeague = match['strLeague']?.toString() ?? '';
                  final league = AppTranslator.translateLeague(rawLeague).toLowerCase();
                  return home.contains(_searchQuery) || away.contains(_searchQuery) || league.contains(_searchQuery);
                }).toList();

                if (filteredMatches.isEmpty) {
                  return const Center(child: Text('Nincs a keresésnek megfelelő mérkőzés.', style: TextStyle(fontSize: 13)));
                }

                final Map<String, List<dynamic>> groupedMatches = {};
                for (var match in filteredMatches) {
                  final rawLeague = match['strLeague'] ?? 'Egyéb bajnokság';
                  final league = AppTranslator.translateLeague(rawLeague); // Központi fordító használata
                  groupedMatches.putIfAbsent(league, () => []).add(match);
                }

                final leagues = groupedMatches.keys.toList();

                return RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: leagues.length,
                    itemBuilder: (context, leagueIndex) {
                      final leagueName = leagues[leagueIndex];
                      final leagueMatches = groupedMatches[leagueName]!;
                      
                      final isCollapsed = _allCollapsed ? !_collapsedLeagues.contains(leagueName) : _collapsedLeagues.contains(leagueName);

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
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              color: const Color(0xFFE2E8F0),
                              child: Row(
                                children: [
                                  const Icon(Icons.sports_soccer, size: 13, color: Colors.black54),
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
                                    isCollapsed ? Icons.expand_more : Icons.expand_less,
                                    size: 16,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (!isCollapsed)
                            ...leagueMatches.map((match) {
                              final homeTeam = match['strHomeTeam'] ?? 'Hazai';
                              final awayTeam = match['strAwayTeam'] ?? 'Vendég';
                              final homeScore = match['intHomeScore'] ?? '-';
                              final awayScore = match['intAwayScore'] ?? '-';
                              final rawStatus = match['strStatus'] ?? match['strProgress'] ?? 'FT';
                              final status = AppTranslator.translateStatus(rawStatus.toString()); // Központi státusz fordító

                              return Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 45,
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: status == 'Vége' ? Colors.grey : Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            homeTeam,
                                            style: const TextStyle(fontSize: 11.5, color: Colors.black87, fontWeight: FontWeight.w500),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            awayTeam,
                                            style: const TextStyle(fontSize: 11.5, color: Colors.black54, fontWeight: FontWeight.w400),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '$homeScore',
                                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.black87),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          '$awayScore',
                                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.black87),
                                        ),
                                      ],
                                    ),
                                  ],
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
