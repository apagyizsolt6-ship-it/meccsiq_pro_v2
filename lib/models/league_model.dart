/*
===========================================
MeccsIQ Pro v2.0
Build: #006
Version: v2.0.0
File: league_model.dart
===========================================
*/

class LeagueModel {
  const LeagueModel({
    required this.id,
    required this.name,
    required this.country,
    this.countryCode,
    this.logo,
    this.flag,
    this.season,
    this.isFavorite = false,
    this.isExpanded = true,
  });

  final int id;

  final String name;

  final String country;

  final String? countryCode;

  final String? logo;

  final String? flag;

  final String? season;

  final bool isFavorite;

  final bool isExpanded;

  LeagueModel copyWith({
    int? id,
    String? name,
    String? country,
    String? countryCode,
    String? logo,
    String? flag,
    String? season,
    bool? isFavorite,
    bool? isExpanded,
  }) {
    return LeagueModel(
      id: id ?? this.id,
      name: name ?? this.name,
      country: country ?? this.country,
      countryCode: countryCode ?? this.countryCode,
      logo: logo ?? this.logo,
      flag: flag ?? this.flag,
      season: season ?? this.season,
      isFavorite: isFavorite ?? this.isFavorite,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }
}
