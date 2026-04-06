import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:yacht/generated/l10n/app_localizations.dart';
import 'package:yacht/game/yacht_game.dart';
import 'package:yacht/model/level_config.dart';
import 'package:yacht/ui/level_selection_screen.dart';

/// Виджет экрана игры с оверлеями (швартовка, проигрыш, победа).
class GameView extends StatelessWidget {
  final YachtMasterGame game;

  const GameView({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    game.l10n = l10n;
    return Scaffold(
      body: Stack(
        children: [
          GameWidget<YachtMasterGame>(
            key: const Key('yacht_game_widget'),
            game: game,
            overlayBuilderMap: {
              'MooringMenu': (context, game) => ListenableBuilder(
                listenable: game.mooringOverlayNotifier,
                builder: (context, _) => MooringOverlay(game: game),
              ),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: l10n.levelInstructionTooltip,
                      onPressed: () {
                        final LevelConfig? level = game.currentLevel;
                        if (level == null) return;
                        showDialog<void>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: const Color(0xFFE0C9A6),
                            title: Text(
                              l10n.levelInstructionTitle,
                              style: const TextStyle(
                                color: Color(0xFF3E2723),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            content: SingleChildScrollView(
                              child: Text(
                                levelLocalizedInstruction(l10n, level),
                                style: TextStyle(
                                  color: Colors.brown.shade900,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: Text(l10n.cancel),
                              ),
                            ],
                          ),
                        );
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFE0C9A6),
                        foregroundColor: const Color(0xFF5D4037),
                        padding: const EdgeInsets.all(12),
                      ),
                      icon: const Text(
                        'i',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      tooltip: l10n.buttonBack,
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFE0C9A6),
                        foregroundColor: const Color(0xFF5D4037),
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
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
    final bool threeLines = game.currentLevel?.mooringSetup.hasMooring == true;
    final bool anchorMode = game.currentLevel?.mooringSetup.hasAnchor == true;
    final bool balticMode = game.currentLevel?.mooringSetup.isBaltic == true;

    Widget? button(bool active, String labelRelease, String labelSecure, bool isSecured, VoidCallback release, VoidCallback secure) {
      if (!active) return null;
      final label = isSecured ? labelRelease : labelSecure;
      final onPressed = isSecured ? release : secure;
      return _mooringButton(label, onPressed);
    }

    if (balticMode) {
      final aftCol = <Widget?>[
        button(game.balticAftPortActive, l10n.mooringGiveAftPilePort, l10n.mooringAftPilePort, yacht.sternPortMooredTo != null, game.releaseBalticAftPort, game.moerBalticAftPort),
        button(game.balticAftStarboardActive, l10n.mooringGiveAftPileStarboard, l10n.mooringAftPileStarboard, yacht.sternStarboardMooredTo != null, game.releaseBalticAftStarboard, game.moerBalticAftStarboard),
      ].whereType<Widget>().toList();
      final bowCol = <Widget?>[
        button(game.balticBowPortActive, l10n.mooringGiveBowPort, l10n.mooringBowPort, yacht.balticBowPortMooredTo != null, game.releaseBalticBowPort, game.moerBalticBowPort),
        button(game.balticBowStarboardActive, l10n.mooringGiveBowStarboard, l10n.mooringBowStarboard, yacht.balticBowStarboardMooredTo != null, game.releaseBalticBowStarboard, game.moerBalticBowStarboard),
      ].whereType<Widget>().toList();
      return Positioned(
        bottom: 24,
        left: 0,
        right: 0,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (aftCol.isNotEmpty)
                Column(mainAxisSize: MainAxisSize.min, children: aftCol.map((b) => Padding(padding: const EdgeInsets.only(bottom: 8), child: b)).toList()),
              if (aftCol.isNotEmpty && bowCol.isNotEmpty) const SizedBox(width: 24),
              if (bowCol.isNotEmpty)
                Column(mainAxisSize: MainAxisSize.min, children: bowCol.map((b) => Padding(padding: const EdgeInsets.only(bottom: 8), child: b)).toList()),
            ],
          ),
        ),
      );
    }

    if (anchorMode) {
      final col = <Widget?>[
        if (game.anchorDropButtonActive && !yacht.isAnchorDropped)
          _mooringButton(l10n.controlDropAnchor, game.dropAnchor),
        button(game.sternPortButtonActiveAnchor, l10n.mooringGiveSternPort, l10n.mooringSternPort, yacht.sternPortMooredTo != null, game.releaseSternPort, game.moerSternPort),
        button(game.sternStarboardButtonActiveAnchor, l10n.mooringGiveSternStarboard, l10n.mooringSternStarboard, yacht.sternStarboardMooredTo != null, game.releaseSternStarboard, game.moerSternStarboard),
      ].whereType<Widget>().toList();
      return Positioned(
        bottom: 24,
        left: 0,
        right: 0,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: col.map((b) => Padding(padding: const EdgeInsets.only(bottom: 8), child: b)).toList(),
          ),
        ),
      );
    }

    if (threeLines) {
      final col1 = <Widget?>[
        button(game.sternPortButtonActive, l10n.mooringGiveSternPort, l10n.mooringSternPort, yacht.sternPortMooredTo != null, game.releaseSternPort, game.moerSternPort),
        button(game.sternStarboardButtonActive, l10n.mooringGiveSternStarboard, l10n.mooringSternStarboard, yacht.sternStarboardMooredTo != null, game.releaseSternStarboard, game.moerSternStarboard),
        button(game.lazyLineButtonActive, l10n.mooringGiveLazyLine, l10n.mooringLazyLine, yacht.lazyLineAnchor != null, game.releaseLazyLine, game.moerLazyLine),
      ].whereType<Widget>().toList();
      return Positioned(
        bottom: 24,
        left: 0,
        right: 0,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: col1.map((b) => Padding(padding: const EdgeInsets.only(bottom: 8), child: b)).toList(),
          ),
        ),
      );
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
