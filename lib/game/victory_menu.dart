import 'package:flutter/material.dart';
import 'package:yacht/generated/l10n/app_localizations.dart';
import '../game/yacht_game.dart';

class VictoryMenu extends StatelessWidget {
  final YachtMasterGame game;

  const VictoryMenu({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green, width: 4),
          boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 10)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.victoryTitle,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 20),
            Text(l10n.victoryMessage, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => game.resetGame(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: Text(l10n.victoryPlayAgain),
            ),
          ],
        ),
      ),
    );
  }
}