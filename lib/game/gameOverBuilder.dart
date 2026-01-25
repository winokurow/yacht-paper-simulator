import 'package:flutter/material.dart';
import 'package:yacht/game/yacht_game.dart';

class GameOverMenu extends StatelessWidget {
  // Передаем ссылку на игру, чтобы достать из неё statusMessage
  final YachtMasterGame game;

  const GameOverMenu({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black45, // Затемнение фона
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.red, width: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'КРАШ!',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 10),
              // ВОТ ЗДЕСЬ мы выводим реальную причину из игры
              Text(
                game.statusMessage,
                style: const TextStyle(fontSize: 18, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => game.resetGame(),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('ПОПРОБОВАТЬ СНОВА', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}