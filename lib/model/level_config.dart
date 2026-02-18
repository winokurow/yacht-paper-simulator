import 'package:flame/extensions.dart';
import 'package:yacht/generated/l10n/app_localizations.dart';

enum EnvironmentType { marina, river, openSea }

/// Тип швартовки уровня: сколько концов и какие (швартовые, шпринги, муринг, якорь).
enum MooringSetup {
  /// Только швартовые (нос, корма) — 2 конца.
  linesOnly,
  /// Швартовые и шпринги — 4 конца (нос, корма, шпринг носовой, шпринг кормовой).
  linesAndSprings,
  /// Швартовые и муринг.
  linesAndMooring,
  /// Швартовые и якорь.
  linesAndAnchor,
  /// Четыре швартовых.
  fourLines,
}

extension MooringSetupExtension on MooringSetup {
  /// Количество швартовых концов (2 или 4) для расчёта тумб и UI.
  int get lineCount => switch (this) {
        MooringSetup.linesOnly => 2,
        MooringSetup.linesAndSprings => 4,
        MooringSetup.linesAndMooring => 2,
        MooringSetup.linesAndAnchor => 2,
        MooringSetup.fourLines => 4,
      };
  /// Есть ли шпринги (показ кнопок шпрингов, 4 позиции тумб).
  bool get hasSprings => this == MooringSetup.linesAndSprings;
}

/// Возвращает локализованное название уровня. Для неизвестного id — [level.name].
String levelLocalizedName(AppLocalizations l10n, LevelConfig level) {
  switch (level.id) {
    case 1:
      return l10n.level1Name;
    case 2:
      return l10n.level2Name;
    default:
      return level.name;
  }
}

/// Возвращает локализованное описание уровня. Для неизвестного id — [level.description].
String levelLocalizedDescription(AppLocalizations l10n, LevelConfig level) {
  switch (level.id) {
    case 1:
      return l10n.level1Description;
    case 2:
      return l10n.level2Description;
    default:
      return level.description;
  }
}

class BoatPlacement {
  final String type; // 'boat' или 'player_slot'
  final double width;
  final double length;
  final String? sprite;
  final bool isNoseRight;

  BoatPlacement({
    required this.type,
    this.width = 4.0,
    this.length = 12.0,
    this.sprite,
    this.isNoseRight = true,
  });
}

class LevelConfig {
  final int id;
  final String name;
  final String description;
  final EnvironmentType envType;
  final Vector2 startPos; // В метрах
  final double startAngle;
  final List<BoatPlacement> marinaLayout;
  final double defaultWindSpeed;
  final double defaultWindDirection; // радианы, откуда дует ветер
  final double defaultCurrentSpeed;
  final double currentDirection;
  /// true для уровня «отход от причала»: яхта стартует с заведёнными концами.
  final bool startWithAllLinesSecured;
  /// Тип швартовки: швартовые, швартовые и шпринги, четыре швартовых и т.д.
  final MooringSetup mooringSetup;
  /// Количество физических кнехтов (тумб). Если null — по умолчанию равно [mooringLinesCount].
  /// Для уровня с шпрингами и 2 кнехтами: 2 — носовой шпринг на заднем, кормовой на переднем.
  final int? bollardCount;

  LevelConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.envType,
    required this.startPos,
    this.startAngle = -90,
    this.marinaLayout = const [],
    this.targetSlotIndex = 0,
    this.defaultWindSpeed = 5.0,
    this.defaultWindDirection = 0.0,
    this.defaultCurrentSpeed = 0.0,
    this.currentDirection = 0.0,
    this.startWithAllLinesSecured = false,
    this.mooringSetup = MooringSetup.linesOnly,
    this.bollardCount,
  });

  final int targetSlotIndex;

  /// Количество швартовых концов для этого уровня (из [mooringSetup]).
  int get mooringLinesCount => mooringSetup.lineCount;
}

class GameLevels {
  static final List<LevelConfig> allLevels = [
    // УРОВЕНЬ 1: швартовые (нос, корма)
    LevelConfig(
      id: 1,
      name: "Первый причал",
      description: "Тихая марина. Запаркуйте яхту в свободный слот между другими судами.",
      envType: EnvironmentType.marina,
      startPos: Vector2(150, 60),
      startAngle: 0, // нос яхты направлен вправо
      mooringSetup: MooringSetup.linesOnly,
      marinaLayout: [
        BoatPlacement(type: 'boat', width: 3.0, length: 8.0, sprite: 'yacht_small.png', isNoseRight: true),
        BoatPlacement(type: 'boat', width: 4.0, length: 12.0, sprite: 'yacht_medium.png', isNoseRight: false),
        BoatPlacement(type: 'boat', width: 5.0, length: 10.0, sprite: 'yacht_motor.png', isNoseRight: true),
        BoatPlacement(type: 'boat', width: 3.0, length: 8.0, sprite: 'yacht_small.png', isNoseRight: false),
        BoatPlacement(type: 'player_slot'), // Твой слот (индекс 4)
        BoatPlacement(type: 'boat', width: 4.0, length: 12.0, sprite: 'yacht_medium.png', isNoseRight: false),
        BoatPlacement(type: 'boat', width: 3.0, length: 9.0, sprite: 'yacht_small.png', isNoseRight: true),
        BoatPlacement(type: 'boat', width: 5.0, length: 10.0, sprite: 'yacht_motor.png', isNoseRight: false),
        BoatPlacement(type: 'boat', width: 4.0, length: 12.0, sprite: 'yacht_medium.png', isNoseRight: true),
        BoatPlacement(type: 'boat', width: 10.0, length: 20.0, sprite: 'yacht_large.png', isNoseRight: true),
      ],
    ),

    // УРОВЕНЬ 2: швартовые и шпринги (4 конца), отход лагом
    LevelConfig(
      id: 2,
      name: "Отход лагом",
      description: "Яхта стоит лагом у причала на 4 концах. Течение давит к причалу. Отдайте концы и отойдите.",
      envType: EnvironmentType.marina,
      startPos: Vector2(186, 6),
      startAngle: 180, // нос влево, борт к причалу (причал сверху)
      defaultCurrentSpeed: 0.26, // ~0.5 уз к причалу
      currentDirection: -1.57, // течение в сторону причала (вверх по экрану)
      startWithAllLinesSecured: true,
      mooringSetup: MooringSetup.linesAndSprings,
      bollardCount: 2, // два кнехта: носовой шпринг на заднем, кормовой на переднем
      marinaLayout: [
        BoatPlacement(type: 'boat', width: 3.0, length: 8.0, sprite: 'yacht_small.png', isNoseRight: true),
        BoatPlacement(type: 'boat', width: 4.0, length: 12.0, sprite: 'yacht_medium.png', isNoseRight: false),
        BoatPlacement(type: 'boat', width: 5.0, length: 10.0, sprite: 'yacht_motor.png', isNoseRight: true),
        BoatPlacement(type: 'boat', width: 3.0, length: 8.0, sprite: 'yacht_small.png', isNoseRight: false),
        BoatPlacement(type: 'player_slot'), // Твой слот (индекс 4)
        BoatPlacement(type: 'boat', width: 4.0, length: 12.0, sprite: 'yacht_medium.png', isNoseRight: false),
        BoatPlacement(type: 'boat', width: 3.0, length: 9.0, sprite: 'yacht_small.png', isNoseRight: true),
        BoatPlacement(type: 'boat', width: 5.0, length: 10.0, sprite: 'yacht_motor.png', isNoseRight: false),
        BoatPlacement(type: 'boat', width: 4.0, length: 12.0, sprite: 'yacht_medium.png', isNoseRight: true),
        BoatPlacement(type: 'boat', width: 10.0, length: 20.0, sprite: 'yacht_large.png', isNoseRight: true),
      ],
    ),
  ];
}