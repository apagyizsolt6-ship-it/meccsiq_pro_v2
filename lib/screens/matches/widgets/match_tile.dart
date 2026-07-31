/*
===========================================
MeccsIQ Pro v2.0
Build: #004
Version: v2.0.0
File: match_tile.dart
===========================================
*/

import 'package:flutter/material.dart';

class MatchTile extends StatelessWidget {
  const MatchTile({
    super.key,
    required this.homeTeam,
    required this.awayTeam,
    required this.kickoff,
    this.homeLogo,
    this.awayLogo,
    this.aiScore,
    this.isLive = false,
    this.isFavorite = false,
    this.onTap,
    this.onFavoriteTap,
  });

  final String homeTeam;
  final String awayTeam;
  final String kickoff;

  final String? homeLogo;
  final String? awayLogo;

  final int? aiScore;

  final bool isLive;
  final bool isFavorite;

  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 5,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [

              SizedBox(
                width: 52,
                child: Column(
                  children: [

                    Text(
                      kickoff,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    if (isLive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "LIVE",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  children: [

                    _teamRow(
                      context,
                      homeLogo,
                      homeTeam,
                    ),

                    const SizedBox(height: 8),

                    _teamRow(
                      context,
                      awayLogo,
                      awayTeam,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              if (aiScore != null)
                Container(
                  width: 48,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _scoreColor(aiScore!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "$aiScore",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              IconButton(
                onPressed: onFavoriteTap,
                icon: Icon(
                  isFavorite
                      ? Icons.star
                      : Icons.star_border,
                  color: isFavorite
                      ? Colors.amber
                      : theme.iconTheme.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamRow(
    BuildContext context,
    String? logo,
    String team,
  ) {
    return Row(
      children: [

        CircleAvatar(
          radius: 12,
          backgroundColor: Colors.transparent,
          backgroundImage:
              logo != null ? NetworkImage(logo) : null,
          child: logo == null
              ? const Icon(
                  Icons.sports_soccer,
                  size: 14,
                )
              : null,
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            team,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Color _scoreColor(int score) {
    if (score >= 90) return Colors.green;

    if (score >= 75) return Colors.orange;

    return Colors.red;
  }
}
