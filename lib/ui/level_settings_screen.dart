import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:yacht/generated/l10n/app_localizations.dart';
import '../model/level_config.dart' show LevelConfig, levelLocalizedName, levelLocalizedDescription;
import '../game/yacht_game.dart';
import '../game/game_view.dart';

/// Экран настроек уровня: ветер, течение, винт.
/// Открывается после выбора уровня, перед запуском игры.
class LevelSettingsScreen extends StatefulWidget {
  final LevelConfig level;

  const LevelSettingsScreen({super.key, required this.level});

  @override
  State<LevelSettingsScreen> createState() => _LevelSettingsScreenState();
}

class _LevelSettingsScreenState extends State<LevelSettingsScreen> {
  late double windMult;
  late double windDirectionDeg;
  late double currentSpeed;
  late double currentDirectionDeg;
  late bool propellerRightHanded;

  @override
  void initState() {
    super.initState();
    windMult = 1.0;
    windDirectionDeg = _radToDeg(widget.level.defaultWindDirection);
    currentSpeed = widget.level.defaultCurrentSpeed;
    currentDirectionDeg = _radToDeg(widget.level.currentDirection);
    propellerRightHanded = true;
  }

  static double _radToDeg(double rad) {
    double deg = rad * 180 / math.pi;
    while (deg < 0) { deg += 360; }
    while (deg >= 360) { deg -= 360; }
    return deg;
  }

  static double _degToRad(double deg) => deg * math.pi / 180;

  static String _directionLabel(AppLocalizations l10n, double deg) {
    final labels = [
      l10n.compassN, l10n.compassNE, l10n.compassE, l10n.compassSE,
      l10n.compassS, l10n.compassSW, l10n.compassW, l10n.compassNW,
    ];
    final i = ((deg + 22.5) / 45).floor() % 8;
    return labels[i];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFF3E2723),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5D4037),
        foregroundColor: Colors.white,
        title: Text(l10n.levelSettingsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0C9A6),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 20,
                            offset: Offset(10, 10),
                          ),
                        ],
                        border: Border.all(color: const Color(0xFF5D4037), width: 3),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            levelLocalizedName(l10n, widget.level).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3E2723),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            levelLocalizedDescription(l10n, widget.level),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.brown.shade800,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const Divider(color: Color(0xFF5D4037), thickness: 2, height: 16),

                          _SectionTitle(title: l10n.sectionWind),
                          _buildCompactSlider(
                            label: l10n.labelStrength,
                            valueText: '${(windMult * 100).toInt()}%',
                            value: windMult,
                            min: 0,
                            max: 2,
                            divisions: 8,
                            onChanged: (v) => setState(() => windMult = v),
                          ),
                          _buildCompactSlider(
                            label: l10n.labelDirection,
                            valueText: '${windDirectionDeg.toInt()}° ${_directionLabel(l10n, windDirectionDeg)}',
                            value: windDirectionDeg,
                            min: 0,
                            max: 360,
                            divisions: 16,
                            onChanged: (v) => setState(() => windDirectionDeg = v),
                          ),
                          const SizedBox(height: 8),

                          _SectionTitle(title: l10n.sectionCurrent),
                          _buildCompactSlider(
                            label: l10n.labelSpeed,
                            valueText: currentSpeed.toStringAsFixed(1),
                            value: currentSpeed,
                            min: 0,
                            max: 2.5,
                            divisions: 10,
                            onChanged: (v) => setState(() => currentSpeed = v),
                          ),
                          _buildCompactSlider(
                            label: l10n.labelDirection,
                            valueText: '${currentDirectionDeg.toInt()}° ${_directionLabel(l10n, currentDirectionDeg)}',
                            value: currentDirectionDeg,
                            min: 0,
                            max: 360,
                            divisions: 16,
                            onChanged: (v) => setState(() => currentDirectionDeg = v),
                          ),
                          const SizedBox(height: 8),

                          _SectionTitle(title: l10n.sectionPropeller),
                          Row(
                            children: [
                              Expanded(
                                child: _propellerChip(
                                  label: l10n.propellerRight,
                                  selected: propellerRightHanded,
                                  onTap: () => setState(() => propellerRightHanded = true),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _propellerChip(
                                  label: l10n.propellerLeft,
                                  selected: !propellerRightHanded,
                                  onTap: () => setState(() => propellerRightHanded = false),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Кнопки всегда внизу экрана, без скролла
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF3E2723),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        l10n.buttonBack,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5D4037),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      onPressed: _startGame,
                      child: Text(
                        l10n.startJourney,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Компактный виджет: лейбл + значение в одной строке, слайдер прямо под ними без лишних отступов.
  Widget _buildCompactSlider({
    required String label,
    required String valueText,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF3E2723))),
            Text(valueText, style: const TextStyle(fontSize: 13, color: Colors.brown)),
          ],
        ),
        SizedBox(
          height: 32,
          child: SliderTheme(
            data: SliderThemeData(
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              activeColor: Colors.brown,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _propellerChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? Colors.brown : Colors.white.withOpacity(0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.brown,
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : Colors.brown,
            ),
          ),
        ),
      ),
    );
  }

  void _startGame() {
    final game = YachtMasterGame();
    game.prepareStart(
      widget.level,
      windMult: windMult,
      windDirectionRad: _degToRad(windDirectionDeg),
      currentSpeed: currentSpeed,
      currentDirectionRad: _degToRad(currentDirectionDeg),
      propellerRightHanded: propellerRightHanded,
    );
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GameView(game: game),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Color(0xFF5D4037),
        ),
      ),
    );
  }
}
