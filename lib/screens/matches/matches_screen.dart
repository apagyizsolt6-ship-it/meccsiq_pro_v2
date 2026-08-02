import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/sports_db_service.dart';

// ==========================================
// VÉGLEGESEN PONTOS KÖZPONTI FORDÍTÓ OSZTÁLY
// ==========================================
class AppTranslator {
  static String translateStatus(String status, String? progress, String? timeStr) {
    final s = status.toUpperCase().trim();
    final p = progress?.trim() ?? '';
    
    if (s == 'FT' || s == 'AET' || s == 'FT_PEN') return 'Vége';
    if (s == 'HT') return 'Félidő';
    
    // Ha van élő játékidő / progress az API-ban (pl. "45", "90", "75'")
    if (p.isNotEmpty && (s.contains('LIVE') || s.contains('IN_PLAY') || s == '1H' || s == '2H' || s == 'ET')) {
      // Ha már van benne apostrof, visszaküldjük, ha csak szám, kiegészítjük '-nel
      if (p.endsWith('\'')) return p;
      return '$p\'';
    }
    
    // Ha félidő van, de a progress-ben nincs benne
    if (s == 'HT') return 'Félidő';
    if (s == '1H') return '1\'';
    if (s == '2H') return '46\'';
    
    // Kezdésre váró meccseknél pontos időpont kiírása
    if (s == 'NS' || s.isEmpty) {
      if (timeStr != null && timeStr.isNotEmpty) {
        if (timeStr.length >= 5) {
          return timeStr.substring(0, 5); // Pl: 19:00:00 -> 19:00
        }
        return timeStr;
      }
      return 'Kezdés';
    }
    
    return s;
  }

  static String? getTranslatedLeague(String apiLeagueName) {
    final l = apiLeagueName.trim().toLowerCase();

    // Nemzetközi kupák
    if (l == 'uefa champions league' || l == 'champions league') return 'Bajnokok Ligája';
    if (l == 'uefa europa league' || l == 'europa league') return 'Európa Liga';
    if (l == 'uefa conference league' || l == 'conference league') return 'Konferencia Liga';

    // Magyarország (szigorúan különválasztva az NB I és NB II)
    if ((l.contains('nb i') || l.contains('nb 1') || l.contains('otp bank liga')) && !l.contains('ii') && !l.contains('2')) {
      return 'Magyarország - NB I';
    }
    if (l.contains('nb ii') || l.contains('nb 2') || l.contains('merkantil')) {
      return 'Magyarország - NB II';
    }
    if (l.contains('magyar kupa')) return 'Magyarország - Magyar Kupa';

    // Anglia
    if ((l.contains('premier league') || l == 'english premier league') && 
        !l.contains('canada') && !l.contains('egypt') && !l.contains('hong kong') && 
        !l.contains('wales') && !l.contains('malta') && !l.contains('non league') && 
        !l.contains('div') && !l.contains('southern') && !l.contains('isthmian')) {
      return 'Anglia - Premier Liga';
    }
    if ((l.contains('championship') || l == 'english championship') && !l.contains('scottish')) {
      return 'Anglia - Másodosztály (Championship)';
    }
    if (l == 'fa cup' || l == 'english fa cup') return 'Anglia - FA Kupa';

    // Top 5 többi része
    if (l.contains('bundesliga') && !l.contains('austrian') && !l.contains('women')) return 'Németország - Bundesliga';
    if (l.contains('2. bundesliga')) return 'Németország - 2. Bundesliga';
    if (l.contains('dfb pokal')) return 'Németország - Német Kupa';
    if (l.contains('ligue 1') && !l.contains('women') && !l.contains('tunisian')) return 'Franciaország - Ligue 1';
    if (l.contains('ligue 2')) return 'Franciaország - Ligue 2';
    if (l.contains('coupe de france')) return 'Franciaország - Francia Kupa';
    if (l.contains('serie a') && !l.contains('brazil') && !l.contains('women')) return 'Olaszország - Serie A';
    if (l.contains('serie b') && !l.contains('brazil')) return 'Olaszország - Serie B';
    if (l.contains('coppa italia')) return 'Olaszország - Olasz Kupa';
    if (l.contains('la liga') || l == 'primera division' || l == 'spain primera division') return 'Spanyolország - La Liga';
    if (l.contains('segunda division') && !l.contains('chile') && !l.contains('argentina')) return 'Spanyolország - 2. Osztály';
    if (l.contains('copa del rey')) return 'Spanyolország - Király Kupa';

    // Többi ország a füzeted alapján
    if (l.contains('primeira liga') || l.contains('portugal 1')) return 'Portugália - 1. Osztály';
    if (l.contains('liga portugal 2') || l.contains('portugal 2')) return 'Portugália - 2. Osztály';
    if (l.contains('eredivisie') || l.contains('netherlands 1')) return 'Hollandia - 1. Osztály';
    if (l.contains('eerste divisie') || l.contains('netherlands 2')) return 'Hollandia - 2. Osztály';
    if (l.contains('belgian pro league') || l.contains('first division a')) return 'Belgium - 1. Osztály';
    if (l.contains('first division b')) return 'Belgium - 2. Osztály';
    if (l.contains('süper lig') || l.contains('turkey 1')) return 'Törökország - 1. Osztály';
    if (l.contains('1. lig') || l.contains('turkey 2')) return 'Törökország - 2. Osztály';
    if (l.contains('ekstraklasa') || l.contains('poland 1')) return 'Lengyelország - 1. Osztály';
    if (l.contains('i liga') || l.contains('poland 2')) return 'Lengyelország - 2. Osztály';
    if (l.contains('czech liga') || l.contains('first league czech')) return 'Csehország - 1. Osztály';
    if (l.contains('super league greece')) return 'Görögország - 1. Osztály';
    if (l.contains('danish superliga')) return 'Dánia - 1. Osztály';
    if (l.contains('1st division denmark')) return 'Dánia - 2. Osztály';
    if (l.contains('eliteserien')) return 'Norvégia - 1. Osztály';
    if (l.contains('1. divisjon')) return 'Norvégia - 2. Osztály';
    if (l.contains('swiss super league')) return 'Svájc - 1. Osztály';
    if (l.contains('challenge league')) return 'Svájc - 2. Osztály';
    if (l.contains('cyprus first division')) return 'Ciprus - 1. Osztály';
    if (l.contains('allsvenskan')) return 'Svédország - 1. Osztály';
    if (l.contains('superettan')) return 'Svédország - 2. Osztály';
    if (l.contains('scottish premiership')) return 'Skócia - 1. Osztály';
    if (l.contains('scottish championship')) return 'Skócia - 2. Osztály';
    if (l.contains('austrian bundesliga')) return 'Ausztria - 1. Osztály';
    if (l.contains('2. liga austria')) return 'Ausztria - 2. Osztály';
    if (l.contains('liga i') && !l.contains('ii')) return 'Románia - 1. Osztály';
    if (l.contains('liga ii')) return 'Románia - 2. Osztály';
    if (l.contains('hnl') || l.contains('croatian football league')) return 'Horvátország - 1. Osztály';
    if (l.contains('slovenian prvaliga')) return 'Szlovénia - 1. Osztály';
    if (l.contains('ukrainian premier league')) return 'Ukrajna - 1. Osztály';
    if (l.contains('ligat ha\'al')) return 'Izrael - 1. Osztály';
    if (l.contains('league of ireland')) return 'Írország - 1. Osztály';
    if (l.contains('armenian premier league')) return 'Örményország - 1. Osztály';
    if (l.contains('football superleague of kosovo')) return 'Koszovó - 1. Osztály';
    if (l.contains('premijer liga')) return 'Bosznia-Hercegovina - 1. Osztály';
    if (l.contains('virsliga')) return 'Lettország - 1. Osztály';
    if (l.contains('veikkausliiga')) return 'Finnország - 1. Osztály';
    if (l.contains('ykkönen')) return 'Finnország - 2. Osztály';
    if (l.contains('kazakhstan premier league')) return 'Kazahsztán - 1. Osztály';
    if (l.contains('faroe islands premier league')) return 'Feröer-szigetek - 1. Osztály';
    if (l.contains('macedonian first football league')) return 'Észak-Macedónia - 1. Osztály';
    if (l.contains('divizia națională')) return 'Moldova - 1. Osztály';
    if (l.contains('kategoria superiore')) return 'Albánia - 1. Osztály';
    if (l.contains('vysshaya liga')) return 'Fehéroroszország - 1. Osztály';
    if (l.contains('a lyga')) return 'Litvánia - 1. Osztály';
    if (l.contains('maltese premier league')) return 'Málta - 1. Osztály';
    if (l.contains('meistriliiga')) return 'Észtország - 1. Osztály';
    if (l.contains('primera divisió')) return 'Andorra - 1. Osztály';
    if (l.contains('erovnuli liga')) return 'Grúzia - 1. Osztály';
    if (l.contains('cymru premier')) return 'Wales - 1. Osztály';
    if (l.contains('argentine') || l.contains('primera división')) return 'Argentína - 1. Osztály';
    if (l.contains('primera b nacional')) return 'Argentína - 2. Osztály';
    if (l.contains('brasileiro') || (l.contains('serie a') && l.contains('brazil'))) return 'Brazília - 1. Osztály';
    if (l.contains('serie b') && l.contains('brazil')) return 'Brazília - 2. Osztály';
    if (l.contains('liga mx')) return 'Mexikó - 1. Osztály';
    if (l.contains('categoría primera a')) return 'Kolumbia - 1. Osztály';
    if (l.contains('major league soccer') || l == 'mls') return 'USA - 1. Osztály';
    if (l.contains('j1 league')) return 'Japán - 1. Osztály';
    if (l.contains('chinese super league')) return 'Kína - 1. Osztály';
    if (l.contains('k league 1')) return 'Dél-Korea - 1. Osztály';
    if (l.contains('persian gulf pro league')) return 'Irán - 1. Osztály';
    if (l.contains('egyptian premier league')) return 'Egyiptom - 1. Osztály';
    if (l.contains('nigerian professional football league')) return 'Nigéria - 1. Osztály';
    if (l.contains('tunisian ligue professionnelle 1')) return 'Tunézia - 1. Osztály';
    if (l.contains('qatar stars league')) return 'Katar - 1. Osztály';
    if (l.contains('saudi pro league')) return 'Szaúd-Arábia - 1. Osztály';
    if (l.contains('philippines football league')) return 'Fülöp-szigetek - 1. Osztály';
    if (l.contains('indian super league')) return 'India - 1. Osztály';
    if (l.contains('hong kong premier league')) return 'Hongkong - 1. Osztály';

    return null;
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
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Frissítés',
            onPressed: _handleRefresh,
          ),
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
                  final isSoccer = sport == 'soccer' || (sport.contains('football') && !sport.contains('american'));
                  if (!isSoccer) return false;

                  final rawLeague = match['strLeague']?.toString() ?? '';
                  return AppTranslator.getTranslatedLeague(rawLeague) != null;
                }).toList();

                final filteredMatches = matches.where((match) {
                  final home = match['strHomeTeam']?.toString().toLowerCase() ?? '';
                  final away = match['strAwayTeam']?.toString().toLowerCase() ?? '';
                  final rawLeague = match['strLeague']?.toString() ?? '';
                  final translatedLeague = AppTranslator.getTranslatedLeague(rawLeague)?.toLowerCase() ?? '';
                  return home.contains(_searchQuery) || away.contains(_searchQuery) || translatedLeague.contains(_searchQuery);
                }).toList();

                if (filteredMatches.isEmpty) {
                  return const Center(child: Text('Nincs a szűrésnek megfelelő mérkőzés.', style: TextStyle(fontSize: 13)));
                }

                final Map<String, List<dynamic>> groupedMatches = {};
                for (var match in filteredMatches) {
                  final rawLeague = match['strLeague'] ?? '';
                  final translatedLeagueName = AppTranslator.getTranslatedLeague(rawLeague) ?? rawLeague;
                  groupedMatches.putIfAbsent(translatedLeagueName, () => []).add(match);
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
                              final homeTeam = match['strHomeTeam']?.toString() ?? 'Hazai';
                              final awayTeam = match['strAwayTeam']?.toString() ?? 'Vendég';
                              final homeScore = match['intHomeScore'] ?? '-';
                              final awayScore = match['intAwayScore'] ?? '-';
                              final rawStatus = match['strStatus'] ?? match['strProgress'] ?? '';
                              final progress = match['strProgress']?.toString();
                              final timeStr = match['strTime']?.toString();
                              
                              final status = AppTranslator.translateStatus(rawStatus.toString(), progress, timeStr);
                              final isTime = status.contains(':');
                              final isLiveMinute = status.endsWith('\'');

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
                                          color: status == 'Vége' 
                                              ? Colors.grey 
                                              : (isLiveMinute ? Colors.red : (isTime ? Colors.blueGrey : Colors.green)),
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
