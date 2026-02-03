import 'package:flutter/material.dart';
import '../game/yacht_game.dart';

class GameOverMenu extends StatelessWidget {
  final YachtMasterGame game;

  const GameOverMenu({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54, // Затемнение игрового экрана
      body: Center(
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: const Color(0xFFE0C9A6), // Цвет картона
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFF5D4037), width: 3),
            boxShadow: const [
              BoxShadow(color: Colors.black87, blurRadius: 20, offset: Offset(10, 10))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ИКОНКА И ЗАГОЛОВОК
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFB71C1C), size: 60),
              const SizedBox(height: 10),
              const Text(
                "АВАРИЙНЫЙ РАПОРТ",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3E2723),
                  letterSpacing: 1.5,
                ),
              ),
              const Divider(color: Color(0xFF5D4037), thickness: 2),

              const SizedBox(height: 20),

              // ПРИЧИНА (Статус из игры)
              Text(
                game.statusMessage.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFB71C1C),
                ),
              ),

              const SizedBox(height: 40),

              // КНОПКИ
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Кнопка Переиграть
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text("ПОПРОБОВАТЬ СНОВА"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5D4037),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: () {
                      game.resetGame(); // Метод в игре, который сбросит всё
                    },
                  ),

                  const SizedBox(height: 12),

                  // Кнопка выхода в меню
                  TextButton.icon(
                    icon: const Icon(Icons.list_alt),
                    label: const Text("В ГЛАВНОЕ МЕНЮ"),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF3E2723),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: () {
                      // Убираем оверлей и выходим из GameView (экран игры)
                      game.overlays.remove('GameOver');
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}