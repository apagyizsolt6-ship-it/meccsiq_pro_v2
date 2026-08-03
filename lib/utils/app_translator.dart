class AppTranslator {
  // Mérkőzés státuszok
  static String translateStatus(String status) {
    final s = status.toUpperCase().trim();
    if (s == 'FT' || s == 'AET' || s == 'FT_PEN') return 'Vége';
    if (s == 'HT') return 'Félidő';
    if (s == 'NS' || s == 'NOT STARTED') return 'Kezdésre vár';
    if (s == '1H') return '1. félidő';
    if (s == '2H') return '2. félidő';
    if (s == 'ET') return 'Hosszabbítás';
    if (s == 'PEN') return 'Büntetők';
    if (s.contains('LIVE') || s.contains('IN_PLAY') || s.contains('INPLAY')) {
      return 'Élő';
    }
    return s;
  }

  // Országok
  static String translateCountry(String country) {
    final c = country.trim().toLowerCase();
    const map = {
      'england': 'Anglia',
      'spain': 'Spanyolország',
      'italy': 'Olaszország',
      'germany': 'Németország',
      'france': 'Franciaország',
      'hungary': 'Magyarország',
      'europe': 'Európa',
      'netherlands': 'Hollandia',
      'portugal': 'Portugália',
      'scotland': 'Skócia',
      'belgium': 'Belgium',
      'turkey': 'Törökország',
      'austria': 'Ausztria',
      'switzerland': 'Svájc',
      'poland': 'Lengyelország',
      'czech republic': 'Csehország',
      'czechia': 'Csehország',
      'croatia': 'Horvátország',
      'serbia': 'Szerbia',
      'romania': 'Románia',
      'ukraine': 'Ukrajna',
      'russia': 'Oroszország',
      'denmark': 'Dánia',
      'sweden': 'Svédország',
      'norway': 'Norvégia',
      'finland': 'Finnország',
      'greece': 'Görögország',
      'argentina': 'Argentína',
      'brazil': 'Brazília',
      'mexico': 'Mexikó',
      'usa': 'USA',
      'world': 'Világ',
    };
    return map[c] ?? country;
  }

  // Bajnokságok
  static String translateLeague(String leagueName) {
    String l = leagueName.trim();

    final exactMatches = {
      // Nemzetközi
      'UEFA Champions League': 'Bajnokok Ligája',
      'UEFA Europa League': 'Európa Liga',
      'Europa Conference League': 'Konferencia Liga',
      'UEFA Europa Conference League': 'Konferencia Liga',
      'UEFA Super Cup': 'UEFA Szuperkupa',
      'UEFA European Championship': 'Európa-bajnokság',
      'UEFA Nations League': 'Nemzetek Ligája',
      'International Friendlies': 'Nemzetközi Felkészülési Mérkőzések',
      'Club Friendlies': 'Klubcsapatok Felkészülési Mérkőzései',
      'World: Club Friendly': 'Klub Felkészülési Mérkőzés',
      'World: Friendly International': 'Nemzetközi Felkészülési Mérkőzés',

      // Anglia
      'Premier League': 'Premier League',
      'English Premier League': 'Premier League',
      'Championship': 'Championship (angol 2.)',
      'English Championship': 'Championship (angol 2.)',
      'League One': 'League One (angol 3.)',
      'League Two': 'League Two (angol 4.)',
      'FA Cup': 'FA Kupa',
      'EFL Cup': 'EFL Kupa',
      'England: Efl Cup - Preliminary': 'EFL Kupa',

      // Németország
      'Bundesliga': 'Bundesliga',
      'German Bundesliga': 'Bundesliga',
      'Bundesliga 2': '2. Bundesliga',
      '2. Bundesliga': '2. Bundesliga',

      // Franciaország
      'Ligue 1': 'Ligue 1',
      'French Ligue 1': 'Ligue 1',
      'Ligue 2': 'Ligue 2',

      // Olaszország
      'Serie A': 'Serie A',
      'Italian Serie A': 'Serie A',
      'Serie B': 'Serie B',

      // Spanyolország
      'Primera': 'La Liga',
      'La Liga': 'La Liga',
      'Spanish La Liga': 'La Liga',
      'Segunda': 'La Liga 2 (Segunda)',
      'Spain Cup': 'Spanyol Kupa',

      // Magyarország
      'NB I': 'NB I',
      'Hungarian NB I': 'NB I',
      'Nb II': 'NB II',
      'Hungarian NB II': 'NB II',
      'Nb III': 'NB III',

      // Egyéb
      'Eredivisie': 'Eredivisie (Holland 1.)',
      'Portuguese Liga': 'Portugál Liga',
      'Primeira Liga': 'Portugál Liga',
      'Swedish Allsvenskan': 'Svéd Allsvenskan',
      'Norwegian Eliteserien': 'Norvég Eliteserien',
      'Danish Superliga': 'Dán Superliga',
      'American Major League Soccer': 'MLS',
      'MLS Next Pro': 'MLS Next Pro',
    };

    if (exactMatches.containsKey(l)) {
      return exactMatches[l]!;
    }

    // Részleges egyezések
    final lower = l.toLowerCase();
    if (lower.contains('champions league')) return 'Bajnokok Ligája';
    if (lower.contains('europa league') && !lower.contains('conference')) {
      return 'Európa Liga';
    }
    if (lower.contains('conference league')) return 'Konferencia Liga';
    if (lower.contains('premier league')) return 'Premier League';
    if (lower.contains('bundesliga') && lower.contains('2')) {
      return '2. Bundesliga';
    }
    if (lower.contains('bundesliga')) return 'Bundesliga';
    if (lower.contains('ligue 1')) return 'Ligue 1';
    if (lower.contains('ligue 2')) return 'Ligue 2';
    if (lower.contains('serie a')) return 'Serie A';
    if (lower.contains('serie b')) return 'Serie B';
    if (lower.contains('la liga') || lower == 'primera') return 'La Liga';
    if (lower.contains('segunda') && !lower.contains('b')) return 'La Liga 2';
    if (lower.contains('nb i') || lower == 'nb i.') return 'NB I';
    if (lower.contains('nb ii')) return 'NB II';

    // Általános helyettesítések
    l = l.replaceAll('Premier Division', 'Premier Liga');
    l = l.replaceAll('First Division', '1. osztály');
    l = l.replaceAll('Second Division', '2. osztály');
    l = l.replaceAll('Friendlies', 'Felkészülési mérkőzések');
    l = l.replaceAll('Super League', 'Szuperliga');
    l = l.replaceAll('Women', 'Női');
    l = l.replaceAll('Cup', 'Kupa');

    return l;
  }

  // Csapatnevek (gyakori / fontosabb)
  static String translateTeam(String teamName) {
    final t = teamName.trim();
    const map = {
      'Inter': 'Inter Milánó',
      'Internazionale': 'Inter Milánó',
      'AC Milan': 'AC Milan',
      'AS Roma': 'AS Roma',
      'SS Lazio': 'Lazio',
      'Juventus': 'Juventus',
      'Napoli': 'Napoli',
      'Atalanta': 'Atalanta',
      'Bayern Munich': 'Bayern München',
      'Bayern München': 'Bayern München',
      'Borussia Dortmund': 'Borussia Dortmund',
      'RB Leipzig': 'RB Leipzig',
      'Bayer Leverkusen': 'Bayer Leverkusen',
      'Paris Saint Germain': 'PSG',
      'Paris Saint-Germain': 'PSG',
      'PSG': 'PSG',
      'Olympique Marseille': 'Olympique Marseille',
      'Olympique Lyonnais': 'Olympique Lyon',
      'Manchester United': 'Manchester United',
      'Manchester City': 'Manchester City',
      'Liverpool': 'Liverpool',
      'Chelsea': 'Chelsea',
      'Arsenal': 'Arsenal',
      'Tottenham': 'Tottenham',
      'Tottenham Hotspur': 'Tottenham',
      'Real Madrid': 'Real Madrid',
      'Barcelona': 'Barcelona',
      'Atletico Madrid': 'Atlético Madrid',
      'Atlético Madrid': 'Atlético Madrid',
      'Sevilla': 'Sevilla',
      'Ajax': 'Ajax',
      'PSV': 'PSV Eindhoven',
      'Feyenoord': 'Feyenoord',
      'Celtic': 'Celtic',
      'Rangers': 'Rangers',
      'Ferencvaros': 'Ferencváros',
      'Ferencváros': 'Ferencváros',
      'FTC': 'Ferencváros',
      'Puskas Academy': 'Puskás Akadémia',
      'Puskás Akadémia': 'Puskás Akadémia',
      'Mol Vidi': 'Fehérvár',
      'Videoton': 'Fehérvár',
      'Debrecen': 'Debrecen',
      'Ujpest': 'Újpest',
      'Újpest': 'Újpest',
      'Honved': 'Honvéd',
      'Budapest Honved': 'Honvéd',
      'Zalaegerszegi': 'Zalaegerszeg',
      'Zalaegerszeg TE': 'Zalaegerszeg',
      'Paks': 'Paks',
      'Kisvarda': 'Kisvárda',
      'Kisvárda': 'Kisvárda',
    };
    return map[t] ?? t;
  }
}
