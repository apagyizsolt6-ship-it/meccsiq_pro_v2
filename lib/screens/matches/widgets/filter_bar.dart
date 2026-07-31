/*
===========================================
MeccsIQ Pro v2.0
Build: #004
Version: v2.0.0
File: filter_bar.dart
===========================================
*/

import 'package:flutter/material.dart';

class FilterBar extends StatefulWidget {
  const FilterBar({
    super.key,
    this.onChanged,
  });

  final ValueChanged<List<String>>? onChanged;

  @override
  State<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<FilterBar> {
  final List<String> _selected = [];

  final List<_FilterItem> _items = const [
    _FilterItem(
      key: "live",
      label: "LIVE",
      icon: Icons.circle,
      color: Colors.red,
    ),
    _FilterItem(
      key: "favorites",
      label: "Kedvencek",
      icon: Icons.star,
      color: Colors.amber,
    ),
    _FilterItem(
      key: "ai",
      label: "AI",
      icon: Icons.psychology,
      color: Colors.green,
    ),
    _FilterItem(
      key: "value",
      label: "Value",
      icon: Icons.trending_up,
      color: Colors.blue,
    ),
  ];

  void _toggle(String key) {
    setState(() {
      if (_selected.contains(key)) {
        _selected.remove(key);
      } else {
        _selected.add(key);
      }
    });

    widget.onChanged?.call(_selected);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = _items[index];
          final selected = _selected.contains(item.key);

          return FilterChip(
            avatar: Icon(
              item.icon,
              size: 16,
              color: item.color,
            ),
            label: Text(
              item.label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            selected: selected,
            onSelected: (_) => _toggle(item.key),
          );
        },
      ),
    );
  }
}

class _FilterItem {
  final String key;
  final String label;
  final IconData icon;
  final Color color;

  const _FilterItem({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
  });
}
