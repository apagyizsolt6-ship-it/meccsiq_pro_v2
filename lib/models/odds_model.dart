/*
===========================================
MeccsIQ Pro v2.0
Build: #006
Version: v2.0.0
File: odds_model.dart
===========================================
*/

class OddsModel {
  const OddsModel({
    required this.home,
    required this.draw,
    required this.away,

    this.bookmaker,
    this.lastUpdate,
  });

  /// Hazai győzelem
  final double home;

  /// Döntetlen
  final double draw;

  /// Vendég győzelem
  final double away;

  /// Fogadóiroda neve
  final String? bookmaker;

  /// Utolsó frissítés
  final DateTime? lastUpdate;

  double get lowestOdd {
    return [home, draw, away].reduce(
      (a, b) => a < b ? a : b,
    );
  }

  double get highestOdd {
    return [home, draw, away].reduce(
      (a, b) => a > b ? a : b,
    );
  }

  OddsModel copyWith({
    double? home,
    double? draw,
    double? away,
    String? bookmaker,
    DateTime? lastUpdate,
  }) {
    return OddsModel(
      home: home ?? this.home,
      draw: draw ?? this.draw,
      away: away ?? this.away,
      bookmaker: bookmaker ?? this.bookmaker,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'home': home,
      'draw': draw,
      'away': away,
      'bookmaker': bookmaker,
      'lastUpdate': lastUpdate?.toIso8601String(),
    };
  }

  factory OddsModel.fromMap(Map<String, dynamic> map) {
    return OddsModel(
      home: (map['home'] as num).toDouble(),
      draw: (map['draw'] as num).toDouble(),
      away: (map['away'] as num).toDouble(),
      bookmaker: map['bookmaker'] as String?,
      lastUpdate: map['lastUpdate'] != null
          ? DateTime.parse(map['lastUpdate'])
          : null,
    );
  }
}
