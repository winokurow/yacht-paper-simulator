import 'package:flutter/material.dart';
import 'package:yacht/game/yacht_game.dart';

class GameOverMenu extends StatelessWidget {
  final YachtMasterGame game;
  const GameOverMenu({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.6), // Затемнение экрана
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('ЛОДКА УШЛА В ОТКРЫТОЕ МОРЕ!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => game.resetGame(),
                  child: const Text('ВЕРНУТЬСЯ В МАРИНУ'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}