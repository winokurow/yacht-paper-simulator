import 'package:flutter/material.dart';
import '../model/level_config.dart';
import 'level_settings_screen.dart';

class LevelSelectionScreen extends StatelessWidget {
  const LevelSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3E2723), // Цвет стола
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFE0C9A6), // Цвет картона
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(10, 10))],
          ),
          child: Column(
            children: [
              const Text(
                "СУДОВОЙ ЖУРНАЛ",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.brown),
              ),
              const Divider(color: Colors.brown, thickness: 2),
              Expanded(
                child: ListView.builder(
                  itemCount: GameLevels.allLevels.length,
                  itemBuilder: (context, index) {
                    final level = GameLevels.allLevels[index];
                    return _buildLevelCard(context, level);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelCard(BuildContext context, LevelConfig level) {
    return Card(
      color: Colors.white.withOpacity(0.5),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: _getIconForType(level.envType),
        title: Text(level.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(level.description),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => _openSettings(context, level),
      ),
    );
  }

  Icon _getIconForType(EnvironmentType type) {
    switch (type) {
      case EnvironmentType.marina: return const Icon(Icons.anchor, color: Colors.blue);
      case EnvironmentType.river: return const Icon(Icons.waves, color: Colors.teal);
      case EnvironmentType.openSea: return const Icon(Icons.explore, color: Colors.indigo);
    }
  }

  void _openSettings(BuildContext context, LevelConfig level) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LevelSettingsScreen(level: level),
      ),
    );
  }
}