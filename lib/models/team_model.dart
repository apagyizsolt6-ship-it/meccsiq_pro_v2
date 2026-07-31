/*
===========================================
MeccsIQ Pro v2.0
Build: #006
Version: v2.0.0
File: team_model.dart
===========================================
*/

class TeamModel {
  const TeamModel({
    required this.id,
    required this.name,
    this.shortName,
    this.logo,
    this.country,
    this.founded,
    this.venue,
    this.isFavorite = false,
  });

  final int id;

  final String name;

  final String? shortName;

  final String? logo;

  final String? country;

  final int? founded;

  final String? venue;

  final bool isFavorite;

  TeamModel copyWith({
    int? id,
    String? name,
    String? shortName,
    String? logo,
    String? country,
    int? founded,
    String? venue,
    bool? isFavorite,
  }) {
    return TeamModel(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      logo: logo ?? this.logo,
      country: country ?? this.country,
      founded: founded ?? this.founded,
      venue: venue ?? this.venue,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
