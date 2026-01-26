import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game/gameOverBuilder.dart';
import 'game/mooring_menu.dart';
import 'game/victory_menu.dart';
import 'game/yacht_game.dart';

void main() {

  final game = YachtMasterGame();
  WidgetsFlutterBinding.ensureInitialized();
    runApp(
      MaterialApp(
        home: Scaffold(
          body: GameWidget<YachtMasterGame>(
            game: YachtMasterGame(),
            overlayBuilderMap: {
              'GameOver': (context, game) => GameOverMenu(game: game),
              'MooringMenu': (context, YachtMasterGame game) => MooringMenu(game: game),
              'Victory': (context, YachtMasterGame game) => VictoryMenu(game: game),
            },
          ),
        ),
      ),
    );
  }