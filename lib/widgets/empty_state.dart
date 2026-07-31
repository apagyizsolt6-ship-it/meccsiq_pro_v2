/*
===========================================
MeccsIQ Pro v2.0
Build: #005
Version: v2.0.0
File: empty_state.dart
===========================================
*/

import 'package:flutter/material.dart';

import 'app_button.dart';
import 'app_card.dart';
import 'app_text.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.buttonText,
    this.onPressed,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? buttonText;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppCard(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Icon(
                icon,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),

              const SizedBox(height: 20),

              AppText.title(
                title,
                align: TextAlign.center,
              ),

              const SizedBox(height: 12),

              AppText.body(
                message,
                align: TextAlign.center,
              ),

              if (buttonText != null && onPressed != null) ...[
                const SizedBox(height: 24),

                AppButton(
                  text: buttonText!,
                  onPressed: onPressed,
                  isExpanded: false,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
