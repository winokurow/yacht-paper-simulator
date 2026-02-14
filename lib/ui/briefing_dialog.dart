import 'package:flutter/material.dart';

import 'package:yacht/generated/l10n/app_localizations.dart';
import '../model/level_config.dart' show LevelConfig, levelLocalizedName, levelLocalizedDescription;
import '../game/yacht_game.dart';
import '../game/game_view.dart';

class BriefingDialog extends StatefulWidget {
  final LevelConfig level;
  const BriefingDialog({super.key, required this.level});

  @override
  State<BriefingDialog> createState() => _BriefingDialogState();
}

class _BriefingDialogState extends State<BriefingDialog> {
  double windMult = 1.0;
  bool isRightHanded = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFE0C9A6),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFF5D4037), width: 3),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 15, offset: Offset(5, 5))
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.briefingTitle(levelLocalizedName(l10n, widget.level).toUpperCase()),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3E2723),
                  fontFamily: 'monospace',
                ),
              ),
              const Divider(color: Color(0xFF5D4037), thickness: 2),

              const SizedBox(height: 15),

              // ОПИСАНИЕ УРОВНЯ
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  levelLocalizedDescription(l10n, widget.level),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF3E2723),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 25),

              Text(
                l10n.briefingSessionSettings,
                style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              const SizedBox(height: 10),

              _buildSettingRow(
                label: l10n.windStrength,
                widget: Expanded(
                  child: Slider(
                    value: windMult,
                    min: 0.0,
                    max: 2.0,
                    divisions: 4,
                    activeColor: Colors.brown,
                    inactiveColor: Colors.black12,
                    label: "${(windMult * 100).toInt()}%",
                    onChanged: (val) => setState(() => windMult = val),
                  ),
                ),
                valueText: "${(windMult * 100).toInt()}%",
              ),

              _buildSettingRow(
                label: l10n.propellerRightHanded,
                widget: Switch(
                  value: isRightHanded,
                  activeColor: Colors.brown,
                  onChanged: (val) => setState(() => isRightHanded = val),
                ),
                valueText: isRightHanded ? l10n.yes : l10n.no,
              ),

              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancel, style: const TextStyle(color: Colors.brown)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5D4037),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    ),
                    onPressed: _startGame,
                    child: Text(l10n.startJourney, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingRow({required String label, required Widget widget, required String valueText}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          widget,
          const SizedBox(width: 10),
          SizedBox(width: 40, child: Text(valueText, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  void _startGame() {
    // 1. Создаем объект игры
    final game = YachtMasterGame();

    // 2. Только ПЕРЕДАЕМ настройки, не вызывая тяжелую логику мира
    game.prepareStart(
      widget.level,
      windMult: windMult,
      windDirectionRad: widget.level.defaultWindDirection,
      currentSpeed: widget.level.defaultCurrentSpeed,
      currentDirectionRad: widget.level.currentDirection,
      propellerRightHanded: isRightHanded,
    );

    // 3. Закрываем диалог
    Navigator.pop(context);

    // 4. Переходим в игру. Когда GameWidget появится на экране,
    // он сам вызовет onLoad, который увидит наши настройки и запустит старт.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GameView(game: game),
      ),
    );
  }
}