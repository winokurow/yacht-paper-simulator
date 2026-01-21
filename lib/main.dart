import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game/yacht_game.dart';

void main() {
  // Создаем экземпляр игры
  final game = YachtMasterGame();

  runApp(
    MaterialApp(
      home: Scaffold(
        body: GameWidget(game: game),
      ),
    ),
  );
}