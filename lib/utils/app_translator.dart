class AppTranslator {
  // Mérkőzés státuszok fordítása
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

  // Bajnokságok és kifejezések intelligens magyarítása
  static String translateLeague(String leagueName) {
    String l = leagueName.trim();
    
    // Pontos egyezések a leggyakoribb bajnokságokra
    final Map<String, String> exactMatches = {
      'International Friendlies': 'Nemzetközi Felkészülési Mérkőzések',
      'Club Friendlies': 'Klubcsapatok Felkészülési Mérkőzései',
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
      'Hungarian NB I': 'Magyar NB I',
      'Hungarian NB II': 'Magyar NB II',
      'English Premier League': 'Angol Premier League',
      'English Championship': 'Angol Másodosztály (Championship)',
      'Spanish La Liga': 'Spanyol La Liga',
      'Italian Serie A': 'Olasz Serie A',
      'German Bundesliga': 'Német Bundesliga',
      'French Ligue 1': 'Francia 1. osztály (Ligue 1)',
    };

    if (exactMatches.containsKey(l)) {
      return exactMatches[l]!;
    }

    // Intelligens helyettesítések ismeretlen / többi bajnokságra
    l = l.replaceAll('Premier Division', 'Premier Liga');
    l = l.replaceAll('First Division', '1. Osztály');
    l = l.replaceAll('Second Division', '2. Osztály');
    l = l.replaceAll('Championship', 'Bajnokság');
    l = l.replaceAll('Division 1', '1. Divízió');
    l = l.replaceAll('Division 2', '2. Divízió');
    l = l.replaceAll('Friendlies', 'Felkészülési Mérkőzések');
    l = l.replaceAll('Super League', 'Szuperliga');
    l = l.replaceAll('Eredivisie', 'Holland 1. osztály (Eredivisie)');
    l = l.replaceAll('Cup', 'Kupa');
    l = l.replaceAll('Women', 'Női');

    return l;
  }
}
