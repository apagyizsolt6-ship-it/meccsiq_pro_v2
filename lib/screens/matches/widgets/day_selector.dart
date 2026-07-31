/*
===========================================
MeccsIQ Pro v2.0
Build: #004
Version: v2.0.0
File: day_selector.dart
===========================================
*/

import 'package:flutter/material.dart';

class DaySelector extends StatefulWidget {
  const DaySelector({
    super.key,
    this.initialIndex = 0,
    this.onChanged,
  });

  final int initialIndex;
  final ValueChanged<int>? onChanged;

  @override
  State<DaySelector> createState() => _DaySelectorState();
}

class _DaySelectorState extends State<DaySelector> {
  late int _selectedIndex;

  final List<Map<String, String>> _days = const [
    {
      "day": "Ma",
      "date": "",
    },
    {
      "day": "Holnap",
      "date": "",
    },
    {
      "day": "H",
      "date": "",
    },
    {
      "day": "K",
      "date": "",
    },
    {
      "day": "Sze",
      "date": "",
    },
    {
      "day": "Cs",
      "date": "",
    },
    {
      "day": "P",
      "date": "",
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 72,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final selected = index == _selectedIndex;

          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              setState(() {
                _selectedIndex = index;
              });

              widget.onChanged?.call(index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 72,
              decoration: BoxDecoration(
                color: selected
                    ? theme.colorScheme.primary
                    : theme.cardColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _days[index]["day"]!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: selected
                          ? Colors.white
                          : theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _days[index]["date"]!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Colors.white70
                          : theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
