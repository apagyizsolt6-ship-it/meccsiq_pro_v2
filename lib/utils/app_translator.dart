class AppTranslator {
  // Mérkőzés státuszok
  static String translateStatus(String status) {
    final s = status.toUpperCase().trim();
    if (s == 'FT' || s == 'AET' || s == 'FT_PEN') return 'Vége';
    if (s == 'HT') return 'Félidő';
    if (s == 'NS' || s == 'NOT STARTED') return 'NS'; // időpontot mutatunk helyette
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
      'armenia': 'Örményország',
      'estonia': 'Észtország',
      'latvia': 'Lettország',
      'lithuania': 'Litvánia',
      'iceland': 'Izland',
      'ireland': 'Írország',
      'india': 'India',
      'bhutan': 'Bhután',
      'bolivia': 'Bolívia',
      'chile': 'Chile',
      'colombia': 'Kolumbia',
      'costa rica': 'Costa Rica',
      'ecuador': 'Ecuador',
      'el salvador': 'El Salvador',
      'guatemala': 'Guatemala',
      'honduras': 'Honduras',
      'paraguay': 'Paraguay',
      'peru': 'Peru',
      'uruguay': 'Uruguay',
      'venezuela': 'Venezuela',
      'bulgaria': 'Bulgária',
      'montenegro': 'Montenegró',
      'slovakia': 'Szlovákia',
      'uzbekistan': 'Üzbegisztán',
      'kyrgyzstan': 'Kirgizisztán',
      'panama': 'Panama',
      'sri lanka': 'Srí Lanka',
    };
    return map[c] ?? country;
  }

  // Bajnokságok – PONTOS egyezés előnyben, ne nyeljen el mindent "Premier League"-nek
  static String translateLeague(String leagueName) {
    String l = leagueName.trim();

    // Először: "Ország: Liga" formátum bontása
    String countryPart = '';
    String namePart = l;
    if (l.contains(':')) {
      final parts = l.split(':');
      countryPart = parts[0].trim();
      namePart = parts.sublist(1).join(':').trim();
    }

    // Pontos / ismert nevek
    final exactMatches = {
      // Nemzetközi
      'UEFA Champions League': 'Bajnokok Ligája',
      'UEFA Europa League': 'Európa Liga',
      'Europa Conference League': 'Konferencia Liga',
      'UEFA Europa Conference League': 'Konferencia Liga',
      'UEFA Super Cup': 'UEFA Szuperkupa',
      'UEFA European Championship': 'Európa-bajnokság',
      'UEFA Nations League': 'Nemzetek Ligája',
      'International Friendlies': 'Nemzetközi felkészülési mérkőzések',
      'Club Friendlies': 'Klub felkészülési mérkőzések',
      'World: Club Friendly': 'Klub felkészülési mérkőzés',
      'World: Friendly International': 'Nemzetközi felkészülési mérkőzés',
      'Club Friendly': 'Klub felkészülési mérkőzés',
      'Friendly International': 'Nemzetközi felkészülési mérkőzés',

      // Anglia – CSAK ezek legyenek "Premier League"
      'Premier League': 'Premier League',
      'English Premier League': 'Premier League',
      'Championship': 'Championship (angol 2.)',
      'English Championship': 'Championship (angol 2.)',
      'League One': 'League One (angol 3.)',
      'League Two': 'League Two (angol 4.)',
      'FA Cup': 'FA Kupa',
      'EFL Cup': 'EFL Kupa',
      'Efl Cup - Preliminary': 'EFL Kupa',
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
      'Segunda': 'La Liga 2',
      'Spain Cup': 'Spanyol Kupa',

      // Magyarország
      'NB I': 'NB I',
      'NB I.': 'NB I',
      'Hungarian NB I': 'NB I',
      'Nb II': 'NB II',
      'Hungarian NB II': 'NB II',
      'Nb III': 'NB III',

      // Egyéb top
      'Eredivisie': 'Eredivisie',
      'Portuguese Liga': 'Portugál Liga',
      'Primeira Liga': 'Portugál Liga',
      'Allsvenskan': 'Allsvenskan',
      'Swedish Allsvenskan': 'Allsvenskan',
      'Eliteserien': 'Eliteserien',
      'Superliga': 'Superliga',
      'Danish Superliga': 'Dán Superliga',
      'Ekstraklasa': 'Ekstraklasa',
      'Premiership': 'Premiership',
    };

    // Teljes név pontos egyezés
    if (exactMatches.containsKey(l)) return exactMatches[l]!;
    if (exactMatches.containsKey(namePart)) {
      final translated = exactMatches[namePart]!;
      // Ha van ország prefix és NEM top liga, tedd ki az országot
      if (countryPart.isNotEmpty &&
          !['Premier League', 'Bundesliga', 'Serie A', 'La Liga', 'Ligue 1', 'NB I', 'NB II']
              .contains(translated)) {
        return '${translateCountry(countryPart)}: $translated';
      }
      return translated;
    }

    final lower = namePart.toLowerCase();
    final fullLower = l.toLowerCase();

    // Nemzetközi kupák (részleges)
    if (fullLower.contains('champions league')) return 'Bajnokok Ligája';
    if (fullLower.contains('europa league') && !fullLower.contains('conference')) {
      return 'Európa Liga';
    }
    if (fullLower.contains('conference league')) return 'Konferencia Liga';

    // Angol Premier – CSAK ha angol / england
    if (lower == 'premier league' || lower == 'english premier league') {
      return 'Premier League';
    }

    // Ország: Premier League → "Örményország: Premier Liga" stb.
    if (lower.contains('premier league') || lower == 'premier liga') {
      if (countryPart.isNotEmpty) {
        return '${translateCountry(countryPart)}: Premier Liga';
      }
      return namePart; // ne nyeld el
    }

    if (lower.contains('bundesliga') && lower.contains('2')) return '2. Bundesliga';
    if (lower.contains('bundesliga')) return 'Bundesliga';
    if (lower.contains('ligue 1')) return 'Ligue 1';
    if (lower.contains('ligue 2')) return 'Ligue 2';
    if (lower.contains('serie a')) return 'Serie A';
    if (lower.contains('serie b')) return 'Serie B';
    if (lower == 'primera' || lower.contains('la liga')) return 'La Liga';
    if (lower.contains('segunda') && !lower.contains('b')) return 'La Liga 2';
    if (lower.contains('nb i') || lower == 'nb i.') return 'NB I';
    if (lower.contains('nb ii')) return 'NB II';

    // Ország prefix megmarad, név finomítva
    String result = namePart;
    result = result.replaceAll('Premier Division', 'Premier Liga');
    result = result.replaceAll('First Division', '1. osztály');
    result = result.replaceAll('Second Division', '2. osztály');
    result = result.replaceAll('Friendlies', 'Felkészülési mérkőzések');
    result = result.replaceAll('Super League', 'Szuperliga');
    result = result.replaceAll('Women', 'Női');
    result = result.replaceAll('Cup', 'Kupa');

    if (countryPart.isNotEmpty) {
      return '${translateCountry(countryPart)}: $result';
    }
    return result;
  }

  // Csapatnevek
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

  /// Dátum formázás megjelenítéshez: "03.08.2026" → "08.03." vagy csak idő
  static String formatMatchTime({
    required String? date,
    required String? time,
    required DateTime selectedDate,
  }) {
    final t = (time ?? '').trim();
    final d = (date ?? '').trim();

    // Parse date: "03.08.2026" vagy "21.08.2026"
    DateTime? matchDate;
    if (d.isNotEmpty) {
      try {
        final parts = d.split('.');
        if (parts.length >= 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          matchDate = DateTime(year, month, day);
        }
      } catch (_) {}
    }

    final sel = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    if (matchDate != null) {
      final sameDay = matchDate.year == sel.year &&
          matchDate.month == sel.month &&
          matchDate.day == sel.day;
      if (sameDay) {
        return t.isNotEmpty ? t : '–';
      }
      // Más nap: "21.08. 19:00"
      final dd = matchDate.day.toString().padLeft(2, '0');
      final mm = matchDate.month.toString().padLeft(2, '0');
      if (t.isNotEmpty) return '$dd.$mm. $t';
      return '$dd.$mm.';
    }

    return t.isNotEmpty ? t : '–';
  }
}
