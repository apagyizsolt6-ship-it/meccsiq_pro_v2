import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/sports_db_service.dart';

// ==========================================
// KÖZPONTI FORDÍTÓ ÉS SZIGORÚ LIGA SZŰRŐ
// ==========================================
class AppTranslator {
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

  // Szigorú ellenőrzés: csak a listán szereplő országok 1-2. osztálya és kupái engedélyezettek
  static bool isAllowedLeague(String leagueName) {
    final l = leagueName.toLowerCase();

    // Nemzetközi kupák (mindig engedélyezve)
    if (l.contains('champions league') || 
        l.contains('europa league') || 
        l.contains('conference league') ||
        l.contains('bajnokok ligája') ||
        l.contains('uefa')) {
      return true;
    }

    // Engedélyezett országok / ligák listája a képek alapján
    final allowedKeywords = [
      // Top 5 + Magyarország (1. és 2. osztály + kupák)
      'nb i', 'nb 1', 'nb ii', 'nb 2', 'magyar kupa',
      'premier league', 'championship', 'fa cup', 'league cup',
      'bundesliga', '2. bundesliga', 'dfb pokal',
      'ligue 1', 'ligue 2', 'coupe de france',
      'serie a', 'serie b', 'coppa italia',
      'la liga', 'copa del rey', 'segunda division',
      
      // Többi ország (1. vagy 2. osztály a listáról)
      'portugal', 'primeira liga', 'liga portugal',
      'hollandia', 'eredivisie', 'eerste divisie',
      'belgium', 'first division a', 'first division b',
      'törökország', 'süper lig', '1. lig',
      'lengyel', 'ekstraklasa', 'i liga',
      'csehország', 'czech liga',
      'görög', 'super league greece',
      'dánia', 'superliga', '1. division',
      'norvégia', 'eliteserien', '1. divisjon',
      'svájc', 'super league', 'challenge league',
      'ciprus', 'first division cyprus',
      'svéd', 'allsvenskan', 'superettan',
      'skócia', 'scottish premiership', 'scottish championship',
      'ausztria', 'austrian bundesliga', '2. liga',
      'románia', 'liga i', 'liga ii',
      'horvátország', 'hnl',
      'szlovénia', 'prva liga',
      'ukrajna', 'premier league ukraine',
      'izrael', 'ligat ha\'al',
      'írország', 'league of ireland',
      'örményország', 'armenian premier league',
      'koszovó', 'football superleague of kosovo',
      'bosznia', 'premijer liga',
      'lettország', 'virsliga',
      'finnország', 'veikkausliiga', 'ykkönen',
      'kazahsztán', 'kazakhstan premier league',
      'feröer', 'faroe islands premier league',
      'észak-macedónia', 'macedonian first football league',
      'moldova', 'divizia națională',
      'albánia', 'kategoria superiore',
      'fehéroroszország', 'vysshaya liga',
      'litvánia', 'a lyga',
      'málta', 'maltese premier league',
      'észtország', 'meistriliiga',
      'andorra', 'primera divisió',
      'grúzia', 'erovnuli liga',
      'wales', 'cymru premier',
      'argentína', 'primera división', 'primera b nacional',
      'brazília', 'serie a', 'serie b',
      'mexikó', 'liga mx',
      'kolumbia', 'categoría primera a',
      'usa', 'major league soccer', 'mls',
      'japán', 'j1 league',
      'kína', 'chinese super league',
      'dél-korea', 'k league 1',
      'irán', 'persian gulf pro league',
      'egyiptom', 'egyptian premier league',
      'nigéria', 'nigerian professional football league',
      'tunézia', 'tunisian ligue professionnelle 1',
      'katar', 'qatar stars league',
      'szaúd-arábia', 'saudi pro league',
      'fülöp-szigetek', 'philippines football league',
      'india', 'indian super league',
      'hongkong', 'hong kong premier league',
    ];

    for (var keyword in allowedKeywords) {
      if (l.contains(keyword)) {
        return true;
      }
    }

    return false; // Ha nincs a listán, kiszűrjük
  }

  static String translateLeague(String leagueName) {
    return leagueName.trim();
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

                // Csak foci + Kizárólag a listán szereplő ligák engedélyezése
                final matches = allEvents.where((match) {
                  final sport = match['strSport']?.toString().toLowerCase() ?? '';
                  final isSoccer = sport == 'soccer' || (sport.contains('football') && !sport.contains('american'));
                  if (!isSoccer) return false;

                  final rawLeague = match['strLeague']?.toString() ?? '';
                  return AppTranslator.isAllowedLeague(rawLeague);
                }).toList();

                final filteredMatches = matches.where((match) {
                  final home = match['strHomeTeam']?.toString().toLowerCase() ?? '';
                  final away = match['strAwayTeam']?.toString().toLowerCase() ?? '';
                  final rawLeague = match['strLeague']?.toString() ?? '';
                  final league = rawLeague.toLowerCase();
                  return home.contains(_searchQuery) || away.contains(_searchQuery) || league.contains(_searchQuery);
                }).toList();

                if (filteredMatches.isEmpty) {
                  return const Center(child: Text('Nincs a szűrésnek megfelelő mérkőzés.', style: TextStyle(fontSize: 13)));
                }

                final Map<String, List<dynamic>> groupedMatches = {};
                for (var match in filteredMatches) {
                  final league = match['strLeague'] ?? 'Egyéb bajnokság';
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
                              final status = AppTranslator.translateStatus(rawStatus.toString());

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
