/*
===========================================
MeccsIQ Pro v2.0
Build: #004
Version: v2.0.0
File: league_header.dart
===========================================
*/

import 'package:flutter/material.dart';

class LeagueHeader extends StatelessWidget {
  const LeagueHeader({
    super.key,
    required this.leagueName,
    required this.country,
    required this.matchCount,
    required this.expanded,
    required this.onTap,
    this.logo,
  });

  final String leagueName;
  final String country;
  final int matchCount;
  final bool expanded;
  final String? logo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [

              if (logo != null)
                CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(logo!),
                  backgroundColor: Colors.transparent,
                )
              else
                const CircleAvatar(
                  radius: 16,
                  child: Icon(Icons.emoji_events),
                ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      leagueName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      country,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "$matchCount",
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              AnimatedRotation(
                duration: const Duration(milliseconds: 180),
                turns: expanded ? .5 : 0,
                child: const Icon(Icons.expand_more),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
