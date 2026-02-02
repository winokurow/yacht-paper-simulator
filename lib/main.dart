import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game/gameOverBuilder.dart';
import 'game/mooring_menu.dart';
import 'game/victory_menu.dart';
import 'game/yacht_game.dart';

void main() async {
  // 1. Обязательно инициализируем биндинги
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Устанавливаем настройки устройства через Flame.device
  await Flame.device.setLandscape();
  await Flame.device.fullScreen();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false, // Убираем дебаг-баннер
      home: Scaffold(
        // Используем SafeArea, чтобы кнопки не залезли под "челку" или камеру
        body: SafeArea(
          child: GameWidget<YachtMasterGame>(
            game: YachtMasterGame(),
            overlayBuilderMap: {
              'GameOver': (context, game) => GameOverMenu(game: game),
              'MooringMenu': (context, game) => MooringMenu(game: game),
              'Victory': (context, game) => VictoryMenu(game: game),
            },
          ),
        ),
      ),
    ),
  );
}