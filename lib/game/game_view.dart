import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:yacht/generated/l10n/app_localizations.dart';
import 'package:yacht/game/yacht_game.dart';
import 'package:yacht/ui/level_selection_screen.dart';

/// Виджет экрана игры с оверлеями (швартовка, проигрыш, победа).
class GameView extends StatelessWidget {
  final YachtMasterGame game;

  const GameView({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    game.l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Stack(
        children: [
          GameWidget<YachtMasterGame>(
            key: const Key('yacht_game_widget'),
            game: game,
            overlayBuilderMap: {
              'MooringMenu': (context, game) => MooringOverlay(game: game),
              'GameOver': (context, game) => GameOverOverlay(game: game),
              'Victory': (context, game) => VictoryOverlay(game: game),
            },
          ),
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFE0C9A6),
                    foregroundColor: const Color(0xFF5D4037),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Оверлей кнопок швартовки (нос/корма).
class MooringOverlay extends StatelessWidget {
  final YachtMasterGame game;
  const MooringOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Positioned(
      bottom: 150,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (game.bowButtonActive)
            _mooringButton(l10n.mooringGiveBow, game.moerBow),
          const SizedBox(width: 20),
          if (game.sternButtonActive)
            _mooringButton(l10n.mooringGiveStern, game.moerStern),
        ],
      ),
    );
  }

  Widget _mooringButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE0C9A6),
        foregroundColor: Colors.brown,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        side: const BorderSide(color: Colors.brown, width: 2),
      ),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

/// Оверлей проигрыша.
class GameOverOverlay extends StatelessWidget {
  final YachtMasterGame game;
  const GameOverOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: Colors.black54,
      child: Center(
        child: paperCard(
          context: context,
          title: l10n.gameOverTitle,
          message: game.statusMessage,
          buttonLabel: l10n.gameOverRetry,
          exitButtonLabel: l10n.gameOverMainMenu,
          onPressed: () => game.resetGame(),
          onExit: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LevelSelectionScreen()),
          ),
        ),
      ),
    );
  }
}

/// Оверлей победы.
class VictoryOverlay extends StatelessWidget {
  final YachtMasterGame game;
  const VictoryOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: Colors.black26,
      child: Center(
        child: paperCard(
          context: context,
          title: l10n.victoryTitle,
          message: l10n.victoryMessageShort,
          buttonLabel: l10n.victoryNextLevel,
          exitButtonLabel: l10n.gameOverMainMenu,
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LevelSelectionScreen()),
          ),
          onExit: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LevelSelectionScreen()),
          ),
        ),
      ),
    );
  }
}

/// Общий стиль карточек меню (paper style).
Widget paperCard({
  required BuildContext context,
  required String title,
  required String message,
  required String buttonLabel,
  required String exitButtonLabel,
  required VoidCallback onPressed,
  required VoidCallback onExit,
}) {
  return Container(
    width: 400,
    padding: const EdgeInsets.all(30),
    decoration: BoxDecoration(
      color: const Color(0xFFE0C9A6),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.brown, width: 3),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),
        const SizedBox(height: 15),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: onPressed,
          child: Text(buttonLabel),
        ),
        TextButton(
          onPressed: onExit,
          child: Text(exitButtonLabel, style: const TextStyle(color: Colors.brown)),
        ),
      ],
    ),
  );
}
