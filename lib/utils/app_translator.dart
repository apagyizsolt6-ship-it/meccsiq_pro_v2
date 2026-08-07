class AppTranslator {
  // Mérkőzés státuszok
  static String translateStatus(String status) {
    final s = status.toUpperCase().trim();
    if (s == 'FT' || s == 'AET' || s == 'FT_PEN') return 'Vége';
    if (s == 'HT') return 'Félidő';
    if (s == 'NS' || s == 'NOT STARTED') return 'NS';
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
      'europe': 'UEFA',
      'uefa': 'UEFA',
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
      'slovenia': 'Szlovénia',
      'uzbekistan': 'Üzbegisztán',
      'kyrgyzstan': 'Kirgizisztán',
      'panama': 'Panama',
      'sri lanka': 'Srí Lanka',
      'belarus': 'Fehéroroszország',
      'bosnia and herzegovina': 'Bosznia-Hercegovina',
      'australia': 'Ausztrália',
      'japan': 'Japán',
      'china': 'Kína',
      'south korea': 'Dél-Korea',
      'saudi arabia': 'Szaúd-Arábia',
      'qatar': 'Katar',
      'egypt': 'Egyiptom',
      'morocco': 'Marokkó',
      'tunisia': 'Tunézia',
      'nigeria': 'Nigéria',
      'south africa': 'Dél-Afrika',
    };
    return map[c] ?? country;
  }

  // Bajnokságok
  static String translateLeague(String leagueName) {
    String l = leagueName.trim();

    String countryPart = '';
    String namePart = l;
    if (l.contains(':')) {
      final parts = l.split(':');
      countryPart = parts[0].trim();
      namePart = parts.sublist(1).join(':').trim();
    }

    final countryLower = countryPart.toLowerCase();
    final nameLower = namePart.toLowerCase();
    final fullLower = l.toLowerCase();

    if (fullLower.contains('champions league')) {
      return 'UEFA – Bajnokok Ligája';
    }
    if (fullLower.contains('europa league') &&
        !fullLower.contains('conference')) {
      return 'UEFA – Európa Liga';
    }
    if (fullLower.contains('conference league')) {
      return 'UEFA – Konferencia Liga';
    }
    if (fullLower.contains('super cup') &&
        (fullLower.contains('uefa') || countryLower == 'europe')) {
      return 'UEFA – Szuperkupa';
    }
    if (fullLower.contains('nations league')) {
      return 'UEFA – Nemzetek Ligája';
    }
    if (fullLower.contains('friendly international') ||
        fullLower == 'international friendlies') {
      return 'Világ – Nemzetközi felkészülési mérkőzés';
    }
    if (fullLower.contains('club friendly') ||
        fullLower == 'club friendlies') {
      return 'Világ – Klub felkészülési mérkőzés';
    }

    if (nameLower == 'premier league' ||
        nameLower == 'english premier league') {
      if (countryPart.isEmpty ||
          countryLower == 'england' ||
          countryLower == 'anglia') {
        return 'Anglia – Premier League';
      }
      return '${translateCountry(countryPart)} – Premier Liga';
    }

    if (nameLower == 'championship' &&
        (countryPart.isEmpty || countryLower == 'england')) {
      return 'Anglia – Championship';
    }
    if (nameLower.contains('efl cup')) return 'Anglia – EFL Kupa';
    if (nameLower == 'fa cup') return 'Anglia – FA Kupa';

    if (nameLower == 'bundesliga') {
      if (countryPart.isEmpty ||
          countryLower == 'germany' ||
          countryLower == 'németország') {
        return 'Németország – Bundesliga';
      }
      return '${translateCountry(countryPart)} – $namePart';
    }
    if (nameLower.contains('bundesliga') && nameLower.contains('2')) {
      if (countryPart.isEmpty ||
          countryLower == 'germany' ||
          countryLower == 'németország') {
        return 'Németország – 2. Bundesliga';
      }
      return '${translateCountry(countryPart)} – $namePart';
    }

    if (nameLower == 'ligue 1') {
      if (countryPart.isEmpty ||
          countryLower == 'france' ||
          countryLower == 'franciaország') {
        return 'Franciaország – Ligue 1';
      }
      return '${translateCountry(countryPart)} – $namePart';
    }
    if (nameLower == 'ligue 2') {
      if (countryPart.isEmpty ||
          countryLower == 'france' ||
          countryLower == 'franciaország') {
        return 'Franciaország – Ligue 2';
      }
      return '${translateCountry(countryPart)} – $namePart';
    }

    // Fontos: a "Serie A" / "Serie B" elnevezést nem csak Olaszország
    // használja (pl. Ecuador első és másodosztálya is így hívja magát) -
    // ezért ország-ellenőrzés nélkül tévesen olasz bajnokságnak jelölte
    // őket. Ugyanazt a védekező mintát alkalmazzuk, mint a Premier
    // League / Championship / La Liga eseteknél.
    if (nameLower == 'serie a') {
      if (countryPart.isEmpty ||
          countryLower == 'italy' ||
          countryLower == 'olaszország') {
        return 'Olaszország – Serie A';
      }
      return '${translateCountry(countryPart)} – $namePart';
    }
    if (nameLower == 'serie b') {
      if (countryPart.isEmpty ||
          countryLower == 'italy' ||
          countryLower == 'olaszország') {
        return 'Olaszország – Serie B';
      }
      return '${translateCountry(countryPart)} – $namePart';
    }

    if (nameLower == 'la liga' || nameLower == 'primera') {
      if (countryPart.isEmpty ||
          countryLower == 'spain' ||
          countryLower == 'spanyolország') {
        return 'Spanyolország – La Liga';
      }
      return '${translateCountry(countryPart)} – $namePart';
    }
    if (nameLower == 'segunda' || nameLower == 'segunda división') {
      if (countryPart.isEmpty ||
          countryLower == 'spain' ||
          countryLower == 'spanyolország') {
        return 'Spanyolország – La Liga 2';
      }
      return '${translateCountry(countryPart)} – Segunda';
    }

    if (nameLower == 'nb i' || nameLower == 'nb i.') {
      return 'Magyarország – NB I';
    }
    if (nameLower == 'nb ii' || nameLower == 'nb ii.') {
      return 'Magyarország – NB II';
    }
    if (nameLower == 'nb iii' || nameLower == 'nb iii.') {
      return 'Magyarország – NB III';
    }

    if (nameLower == 'eredivisie') return 'Hollandia – Eredivisie';
    if (nameLower == 'portuguese liga' || nameLower == 'primeira liga') {
      return 'Portugália – Liga Portugal';
    }
    if (nameLower == 'allsvenskan') return 'Svédország – Allsvenskan';
    if (nameLower == 'eliteserien') return 'Norvégia – Eliteserien';
    if (nameLower == 'superliga' && countryLower == 'denmark') {
      return 'Dánia – Superliga';
    }
    if (nameLower == 'ekstraklasa') return 'Lengyelország – Ekstraklasa';
    if (nameLower == 'premiership' &&
        (countryLower == 'scotland' || countryPart.isEmpty)) {
      return 'Skócia – Premiership';
    }

    String result = namePart;
    result = result.replaceAll('Premier Division', 'Premier Liga');
    result = result.replaceAll('First Division', '1. osztály');
    result = result.replaceAll('Second Division', '2. osztály');
    result = result.replaceAll('Friendlies', 'Felkészülési mérkőzések');
    result = result.replaceAll('Super League', 'Szuperliga');
    result = result.replaceAll('Women', 'Női');
    result = result.replaceAll('Cup', 'Kupa');

    if (countryPart.isNotEmpty) {
      return '${translateCountry(countryPart)} – $result';
    }
    return result;
  }

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

  /// UTC idő → helyi idő (pl. 19:00 UTC → 21:00 CEST)
  static String toLocalTime(String? timeUtc) {
    if (timeUtc == null || timeUtc.trim().isEmpty) return '–';
    final cleaned = timeUtc.trim();
    final parts = cleaned.split(':');
    if (parts.length < 2) return cleaned;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return cleaned;

    final now = DateTime.now();
    final utc = DateTime.utc(now.year, now.month, now.day, h, m);
    final local = utc.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  /// Kezdési idő megjelenítése (helyi időzónában)
  static String formatMatchTime({
    required String? date,
    required String? time,
    required DateTime selectedDate,
  }) {
    final tLocal = toLocalTime(time);
    final d = (date ?? '').trim();

    DateTime? matchDate;
    if (d.isNotEmpty) {
      try {
        final parts = d.split('.');
        if (parts.length >= 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          matchDate = DateTime(year, month, day);
        } else if (d.contains('-')) {
          matchDate = DateTime.tryParse(d);
        }
      } catch (_) {}
    }

    final sel =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    if (matchDate != null) {
      final sameDay = matchDate.year == sel.year &&
          matchDate.month == sel.month &&
          matchDate.day == sel.day;
      if (sameDay) {
        return tLocal;
      }
      final dd = matchDate.day.toString().padLeft(2, '0');
      final mm = matchDate.month.toString().padLeft(2, '0');
      if (tLocal != '–') return '$dd.$mm. $tLocal';
      return '$dd.$mm.';
    }

    return tLocal;
  }
}
