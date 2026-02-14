import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yacht/generated/l10n/app_localizations.dart';
import 'package:yacht/l10n/locale_notifier.dart';
import '../model/level_config.dart' show EnvironmentType, GameLevels, LevelConfig, levelLocalizedName, levelLocalizedDescription;
import 'level_settings_screen.dart';

class LevelSelectionScreen extends StatelessWidget {
  const LevelSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFF3E2723),
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFE0C9A6),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(10, 10))],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.levelSelectionTitle,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.brown),
                  ),
                  _LanguageSelector(),
                ],
              ),
              const Divider(color: Colors.brown, thickness: 2),
              Expanded(
                child: ListView.builder(
                  itemCount: GameLevels.allLevels.length,
                  itemBuilder: (context, index) {
                    final level = GameLevels.allLevels[index];
                    return _buildLevelCard(context, level, l10n);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelCard(BuildContext context, LevelConfig level, AppLocalizations l10n) {
    return Card(
      color: Colors.white.withOpacity(0.5),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: _getIconForType(level.envType),
        title: Text(levelLocalizedName(l10n, level), style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(levelLocalizedDescription(l10n, level)),
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

class _LanguageSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeNotifier = context.watch<LocaleNotifier>();
    final current = localeNotifier.locale;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.settingsSelectLanguage, style: const TextStyle(fontSize: 12, color: Colors.brown)),
        const SizedBox(width: 8),
        DropdownButton<Locale>(
          value: current,
          items: const [
            DropdownMenuItem(value: Locale('en'), child: Text('EN')),
            DropdownMenuItem(value: Locale('ru'), child: Text('RU')),
            DropdownMenuItem(value: Locale('de'), child: Text('DE')),
          ],
          onChanged: (Locale? value) {
            if (value != null) context.read<LocaleNotifier>().setLocale(value);
          },
        ),
      ],
    );
  }
}