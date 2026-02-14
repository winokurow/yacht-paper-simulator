import 'package:flutter/material.dart';
import 'package:yacht/generated/l10n/app_localizations.dart';
import '../game/yacht_game.dart';

class MooringMenu extends StatelessWidget {
  final YachtMasterGame game;

  const MooringMenu({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      children: [
        Positioned(
          bottom: 140,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (game.bowButtonActive)
                _MooringButton(
                  label: l10n.mooringBow,
                  onPressed: game.moerBow,
                ),
              if (game.bowButtonActive && game.sternButtonActive)
                const SizedBox(width: 20),
              if (game.sternButtonActive)
                _MooringButton(
                  label: l10n.mooringStern,
                  onPressed: game.moerStern,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// Приватный виджет кнопки, чтобы не дублировать стили
class _MooringButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _MooringButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.withOpacity(0.8),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 5,
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}