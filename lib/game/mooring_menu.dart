import 'package:flutter/material.dart';
import '../game/yacht_game.dart';

class MooringMenu extends StatelessWidget {
  final YachtMasterGame game;

  const MooringMenu({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          bottom: 140, // Настройте высоту под ваш интерфейс
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Кнопка для носа
              if (game.bowButtonActive)
                _MooringButton(
                  label: 'НОСОВОЙ',
                  onPressed: game.moerBow,
                ),

              // Разделитель, если обе кнопки активны
              if (game.bowButtonActive && game.sternButtonActive)
                const SizedBox(width: 20),

              // Кнопка для кормы
              if (game.sternButtonActive)
                _MooringButton(
                  label: 'КОРМОВОЙ',
                  onPressed: game.moerStern,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// Приватный виджет кнопки, чтобы не дублировать стили
class _MooringButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _MooringButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.withOpacity(0.8),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 5,
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}