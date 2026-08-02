import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/sports_db_service.dart';

// ==========================================
// PONTOS ÉS TÉVEDHETETLEN KÖZPONTI FORDÍTÓ
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

  // Kizárólag a hivatalos, pontos API nevek alapján párosítunk magyar névre
  static String? getTranslatedLeague(String apiLeagueName) {
    final l = apiLeagueName.trim().toLowerCase();

    // Nemzetközi kupák
    if (l == 'uefa champions league' || l == 'champions league') return 'Bajnokok Ligája';
    if (l == 'uefa europa league' || l == 'europa league') return 'Európa Liga';
    if (l == 'uefa conference league' || l == 'conference league') return 'Konferencia Liga';

    // Magyarország
    if (l == 'nb i' || l == 'otp bank liga' || l == 'hungary nb i') return 'Magyarország - NB I';
    if (l == 'nb ii' || l == 'hungary nb ii') return 'Magyarország - NB II';
    if (l == 'magyar kupa') return 'Magyarország - Magyar Kupa';

    // Top 5 + Kupák
    if (l == 'premier league') return 'Anglia - Premier Liga';
    if (l == 'championship') return 'Anglia - Másodosztály (Championship)';
    if (l == 'fa cup') return 'Anglia - FA Kupa';
    if (l == 'bundesliga') return 'Németország - Bundesliga';
    if (l == '2. bundesliga') return 'Németország - 2. Bundesliga';
    if (l == 'dfb pokal') return 'Németország - Német Kupa';
    if (l == 'ligue 1') return 'Franciaország - Ligue 1';
    if (l == 'ligue 2') return 'Franciaország - Ligue 2';
    if (l == 'coupe de france') return 'Franciaország - Francia Kupa';
    if (l == 'serie a') return 'Olaszország - Serie A';
    if (l == 'serie b') return 'Olaszország - Serie B';
    if (l == 'coppa italia') return 'Olaszország - Olasz Kupa';
    if (l == 'la liga' || l == 'primera division') return 'Spanyolország - La Liga';
    if (l == 'segunda division') return 'Spanyolország - 2. Osztály';
    if (l == 'copa del rey') return 'Spanyolország - Király Kupa';

    // Többi ország a füzeted alapján
    if (l == 'primeira liga') return 'Portugália - 1. Osztály';
    if (l == 'liga portugal 2') return 'Portugália - 2. Osztály';
    if (l == 'eredivisie') return 'Hollandia - 1. Osztály';
    if (l == 'eerste divisie') return 'Hollandia - 2. Osztály';
    if (l == 'belgian pro league' || l == 'first division a') return 'Belgium - 1. Osztály';
    if (l == 'first division b') return 'Belgium - 2. Osztály';
    if (l == 'süper lig') return 'Törökország - 1. Osztály';
    if (l == '1. lig') return 'Törökország - 2. Osztály';
    if (l == 'ekstraklasa') return 'Lengyelország - 1. Osztály';
    if (l == 'i liga') return 'Lengyelország - 2. Osztály';
    if (l == 'czech liga' || l == 'first league czech') return 'Csehország - 1. Osztály';
    if (l == 'super league greece') return 'Görögország - 1. Osztály';
    if (l == 'danish superliga') return 'Dánia - 1. Osztály';
    if (l == '1st division denmark') return 'Dánia - 2. Osztály';
    if (l == 'eliteserien') return 'Norvégia - 1. Osztály';
    if (l == '1. divisjon') return 'Norvégia - 2. Osztály';
    if (l == 'swiss super league') return 'Svájc - 1. Osztály';
    if (l == 'challenge league') return 'Svájc - 2. Osztály';
    if (l == 'cyprus first division') return 'Ciprus - 1. Osztály';
    if (l == 'allsvenskan') return 'Svédország - 1. Osztály';
    if (l == 'superettan') return 'Svédország - 2. Osztály';
    if (l == 'scottish premiership') return 'Skócia - 1. Osztály';
    if (l == 'scottish championship') return 'Skócia - 2. Osztály';
    if (l == 'austrian bundesliga') return 'Ausztria - 1. Osztály';
    if (l == '2. liga austria') return 'Ausztria - 2. Osztály';
    if (l == 'liga i') return 'Románia - 1. Osztály';
    if (l == 'liga ii') return 'Románia - 2. Osztály';
    if (l == 'hnl' || l == 'croatian football league') return 'Horvátország - 1. Osztály';
    if (l == 'slovenian prvaliga') return 'Szlovénia - 1. Osztály';
    if (l == 'ukrainian premier league') return 'Ukrajna - 1. Osztály';
    if (l == 'ligat ha\'al') return 'Izrael - 1. Osztály';
    if (l == 'league of ireland premier division') return 'Írország - 1. Osztály';
    if (l == 'armenian premier league') return 'Örményország - 1. Osztály';
    if (l == 'football superleague of kosovo') return 'Koszovó - 1. Osztály';
    if (l == 'premijer liga') return 'Bosznia-Hercegovina - 1. Osztály';
    if (l == 'virsliga') return 'Lettország - 1. Osztály';
    if (l == 'veikkausliiga') return 'Finnország - 1. Osztály';
    if (l == 'ykkönen') return 'Finnország - 2. Osztály';
    if (l == 'kazakhstan premier league') return 'Kazahsztán - 1. Osztály';
    if (l == 'faroe islands premier league') return 'Feröer-szigetek - 1. Osztály';
    if (l == 'macedonian first football league') return 'Észak-Macedónia - 1. Osztály';
    if (l == 'divizia națională') return 'Moldova - 1. Osztály';
    if (l == 'kategoria superiore') return 'Albánia - 1. Osztály';
    if (l == 'vysshaya liga') return 'Fehéroroszország - 1. Osztály';
    if (l == 'a lyga') return 'Litvánia - 1. Osztály';
    if (l == 'maltese premier league') return 'Málta - 1. Osztály';
    if (l == 'meistriliiga') return 'Észtország - 1. Osztály';
    if (l == 'primera divisió') return 'Andorra - 1. Osztály';
    if (l == 'erovnuli liga') return 'Grúzia - 1. Osztály';
    if (l == 'cymru premier') return 'Wales - 1. Osztály';
    if (l == 'argentine primera división') return 'Argentína - 1. Osztály';
    if (l == 'primera b nacional') return 'Argentína - 2. Osztály';
    if (l == 'brazileiro serie a') return 'Brazília - 1. Osztály';
    if (l == 'brazileiro serie b') return 'Brazília - 2. Osztály';
    if (l == 'liga mx') return 'Mexikó - 1. Osztály';
    if (l == 'categoría primera a') return 'Kolumbia - 1. Osztály';
    if (l == 'major league soccer' || l == 'mls') return 'USA - 1. Osztály';
    if (l == 'j1 league') return 'Japán - 1. Osztály';
    if (l == 'chinese super league') return 'Kína - 1. Osztály';
    if (l == 'k league 1') return 'Dél-Korea - 1. Osztály';
    if (l == 'persian gulf pro league') return 'Irán - 1. Osztály';
    if (l == 'egyptian premier league') return 'Egyiptom - 1. Osztály';
    if (l == 'nigerian professional football league') return 'Nigéria - 1. Osztály';
    if (l == 'tunisian ligue professionnelle 1') return 'Tunézia - 1. Osztály';
    if (l == 'qatar stars league') return 'Katar - 1. Osztály';
    if (l == 'saudi pro league') return 'Szaúd-Arábia - 1. Osztály';
    if (l == 'philippines football league') return 'Fülöp-szigetek - 1. Osztály';
    if (l == 'indian super league') return 'India - 1. Osztály';
    if (l == 'hong kong premier league') return 'Hongkong - 1. Osztály';

    return null; // Ha nem egyezik pontosan egyikkel sem, semmilyen hülyeséget nem enged át!
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
