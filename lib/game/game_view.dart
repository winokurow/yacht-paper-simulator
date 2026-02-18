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

/// Оверлей кнопок швартовки: два столбца (кормовые | носовые), по два ряда.
class MooringOverlay extends StatelessWidget {
  final YachtMasterGame game;
  const MooringOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final yacht = game.yacht;

    Widget? button(bool active, String labelRelease, String labelSecure, bool isSecured, VoidCallback release, VoidCallback secure) {
      if (!active) return null;
      final label = isSecured ? labelRelease : labelSecure;
      final onPressed = isSecured ? release : secure;
      return _mooringButton(label, onPressed);
    }

    final sternCol = <Widget?>[
      button(game.sternButtonActive, l10n.mooringGiveStern, l10n.mooringStern, yacht.sternMooredTo != null, game.releaseStern, game.moerStern),
      button(game.backSpringButtonActive, l10n.mooringGiveBackSpring, l10n.mooringBackSpring, yacht.backSpringMooredTo != null, game.releaseBackSpring, game.moerBackSpring),
    ].whereType<Widget>().toList();
    final bowCol = <Widget?>[
      button(game.bowButtonActive, l10n.mooringGiveBow, l10n.mooringBow, yacht.bowMooredTo != null, game.releaseBow, game.moerBow),
      button(game.forwardSpringButtonActive, l10n.mooringGiveForwardSpring, l10n.mooringForwardSpring, yacht.forwardSpringMooredTo != null, game.releaseForwardSpring, game.moerForwardSpring),
    ].whereType<Widget>().toList();

    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (sternCol.isNotEmpty)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: sternCol.map((b) => Padding(padding: const EdgeInsets.only(bottom: 8), child: b)).toList(),
              ),
            if (sternCol.isNotEmpty && bowCol.isNotEmpty) const SizedBox(width: 24),
            if (bowCol.isNotEmpty)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: bowCol.map((b) => Padding(padding: const EdgeInsets.only(bottom: 8), child: b)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _mooringButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE0C9A6),
        foregroundColor: Colors.brown,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: const BorderSide(color: Colors.brown, width: 2),
      ),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
    final bool isDepartLevel = game.currentLevel?.startWithAllLinesSecured == true;
    return Container(
      color: Colors.black26,
      child: Center(
        child: paperCard(
          context: context,
          title: isDepartLevel ? l10n.victoryTitleDeparted : l10n.victoryTitle,
          message: isDepartLevel ? l10n.victoryMessageShortDeparted : l10n.victoryMessageShort,
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
