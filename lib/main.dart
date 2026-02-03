import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game/yacht_game.dart';
import 'ui/level_selection_screen.dart';

void main() async {
  // 1. Инициализация Flutter и настроек экрана
  WidgetsFlutterBinding.ensureInitialized();

  // Принудительный ландшафт и полноэкранный режим
  await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Yacht Master',
      theme: ThemeData(
        fontFamily: 'monospace',
        primarySwatch: Colors.brown,
      ),
      // Приложениие начинается с экрана выбора уровней
      home: const LevelSelectionScreen(),
    ),
  );
}

// Это основной виджет, который запускает игру
class GameView extends StatelessWidget {
  final YachtMasterGame game;

  const GameView({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget<YachtMasterGame>(
        game: game,
        // РЕГИСТРАЦИЯ ОВЕРЛЕЕВ
        overlayBuilderMap: {
          // 1. Кнопки швартовки
          'MooringMenu': (context, game) => _MooringOverlay(game: game),

          // 2. Окно проигрыша
          'GameOver': (context, game) => _GameOverOverlay(game: game),

          // 3. Окно победы
          'Victory': (context, game) => _VictoryOverlay(game: game),
        },
      ),
    );
  }
}

// --- ВИДЖЕТЫ ОВЕРЛЕЕВ ---

class _MooringOverlay extends StatelessWidget {
  final YachtMasterGame game;
  const _MooringOverlay({required this.game});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 150, // Выше панели приборов
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (game.bowButtonActive)
            _mooringButton("ПОДАТЬ НОСОВОЙ", game.moerBow),
          const SizedBox(width: 20),
          if (game.sternButtonActive)
            _mooringButton("ПОДАТЬ КОРМОВОЙ", game.moerStern),
        ],
      ),
    );
  }

  Widget _mooringButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE0C9A6),
        foregroundColor: Colors.brown,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        side: const BorderSide(color: Colors.brown, width: 2),
      ),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  final YachtMasterGame game;
  const _GameOverOverlay({required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: _paperCard(
          title: "ПРОИСШЕСТВИЕ",
          message: game.statusMessage,
          buttonLabel: "ПЕРЕИГРАТЬ",
          onPressed: () => game.resetGame(),
          onExit: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LevelSelectionScreen()),
          ),
        ),
      ),
    );
  }
}

class _VictoryOverlay extends StatelessWidget {
  final YachtMasterGame game;
  const _VictoryOverlay({required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black26,
      child: Center(
        child: _paperCard(
          title: "УСПЕШНАЯ ШВАРТОВКА",
          message: "Судно надежно закреплено в порту.",
          buttonLabel: "СЛЕДУЮЩИЙ УРОВЕНЬ",
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

// Общий стиль для карточек меню
Widget _paperCard({
  required String title,
  required String message,
  required String buttonLabel,
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
          child: const Text("В ГЛАВНОЕ МЕНЮ", style: TextStyle(color: Colors.brown)),
        ),
      ],
    ),
  );
}