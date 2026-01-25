import 'package:flutter/material.dart';
import '../game/yacht_game.dart';

class VictoryMenu extends StatelessWidget {
  final YachtMasterGame game;

  const VictoryMenu({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
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
            const Text(
              'УСПЕШНАЯ ШВАРТОВКА!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 20),
            const Text('Вы идеально закрепили судно.', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => game.resetGame(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text('ИГРАТЬ СНОВА'),
            ),
          ],
        ),
      ),
    );
  }
}