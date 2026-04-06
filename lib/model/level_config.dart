import 'package:flame/extensions.dart';
import 'package:yacht/generated/l10n/app_localizations.dart';

enum EnvironmentType { marina, river, openSea }

/// Тип швартовки уровня: сколько концов и какие (швартовые, шпринги, муринг, якорь).
enum MooringSetup {
  /// Только швартовые (нос, корма) — 2 конца.
  linesOnly,
  /// Швартовые и шпринги — 4 конца (нос, корма, шпринг носовой, шпринг кормовой).
  linesAndSprings,
  /// Швартовка кормой с мурингом: 2 кормовых (порт/левый, правый/старборд) + 1 муринг (ленивый конец от носа к якорю).
  linesAndMooring,
  /// Швартовые и якорь.
  linesAndAnchor,
  /// Четыре швартовых.
  fourLines,
  /// Baltic style: нос к причалу (2 носовых к тумбам) + корма к сваям (2 кормовых к сваям).
  balticStyle,
}

extension MooringSetupExtension on MooringSetup {
  /// Количество концов (2, 3 или 4) для расчёта тумб и UI.
  int get lineCount => switch (this) {
        MooringSetup.linesOnly => 2,
        MooringSetup.linesAndSprings => 4,
        MooringSetup.linesAndMooring => 3,
        MooringSetup.linesAndAnchor => 2,
        MooringSetup.fourLines => 4,
        MooringSetup.balticStyle => 4,
      };
  /// Есть ли шпринги (показ кнопок шпрингов, 4 позиции тумб).
  bool get hasSprings => this == MooringSetup.linesAndSprings;
  /// Швартовка кормой с мурингом: 2 кормовых к причалу + 1 муринг (ленивый конец к якорю).
  bool get hasMooring => this == MooringSetup.linesAndMooring;
  /// Швартовка кормой с якорем: сброс якоря + 2 кормовых к причалу.
  bool get hasAnchor => this == MooringSetup.linesAndAnchor;
  /// Baltic style: нос к причалу + корма к сваям (4 конца).
  bool get isBaltic => this == MooringSetup.balticStyle;
}

/// Возвращает локализованное название уровня. Для неизвестного id — [level.name].
String levelLocalizedName(AppLocalizations l10n, LevelConfig level) {
  switch (level.id) {
    case 1:
      return l10n.level1Name;
    case 2:
      return l10n.level2Name;
    case 3:
      return l10n.level3Name;
    case 4:
      return l10n.level4Name;
    case 5:
      return l10n.level5Name;
    case 6:
      return l10n.level6Name;
    case 7:
      return l10n.level7Name;
    case 8:
      return l10n.level8Name;
    case 9:
      return l10n.level9Name;
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
    case 3:
      return l10n.level3Description;
    case 4:
      return l10n.level4Description;
    case 5:
      return l10n.level5Description;
    case 6:
      return l10n.level6Description;
    case 7:
      return l10n.level7Description;
    case 8:
      return l10n.level8Description;
    case 9:
      return l10n.level9Description;
    default:
      return level.description;
  }
}

/// Возвращает локализованную инструкцию по уровню (для диалога в игре).
String levelLocalizedInstruction(AppLocalizations l10n, LevelConfig level) {
  switch (level.id) {
    case 1:
      return l10n.levelInstruction1;
    case 2:
      return l10n.levelInstruction2;
    case 3:
      return l10n.levelInstruction3;
    case 4:
      return l10n.levelInstruction4;
    case 5:
      return l10n.levelInstruction5;
    case 6:
      return l10n.levelInstruction6;
    case 7:
      return l10n.levelInstruction7;
    case 8:
      return l10n.levelInstruction8;
    case 9:
      return l10n.levelInstruction9;
    default:
      return levelLocalizedDescription(l10n, level);
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
  /// Позиция «мёртвого якоря» муринга в мире (метры). Только для [MooringSetup.linesAndMooring].
  final Vector2? mooringAnchorPositionMeters;
  /// Целевой угол яхты для победы (градусы). Для уровня 3 — перпендикуляр причалу (90° или 270°).
  final double? targetAngleDegrees;
  /// Ширина зоны победы в «ширинах яхты». Если задано (например 2.0), маркер слота строится по нему.
  final double? greenZoneWidthInYachtWidths;
  /// Доли ширины слота для позиций кнехтов (0..1). Если задано, используются вместо стандартных.
  final List<double>? bollardPositionFactors;
  /// Центр зоны сброса якоря (метры). Только для [MooringSetup.linesAndAnchor].
  final Vector2? anchorDropZoneCenterMeters;
  /// Позиции свай (метры). Порядок: [aft port, aft starboard, fwd port, fwd starboard].
  /// Только для [MooringSetup.balticStyle].
  final List<Vector2>? pilePositionsMeters;
  /// Узкая марина: канал с препятствиями (MooredYacht) по бокам.
  final bool isNarrowMarina;

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
    this.mooringAnchorPositionMeters,
    this.targetAngleDegrees,
    this.greenZoneWidthInYachtWidths,
    this.bollardPositionFactors,
    this.anchorDropZoneCenterMeters,
    this.pilePositionsMeters,
    this.isNarrowMarina = false,
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

    // УРОВЕНЬ 3: швартовка кормой с мурингом (2 кормовых + ленивый конец к якорю)
    LevelConfig(
      id: 3,
      name: "Кормой к причалу",
      description: "Швартовка кормой: кормовой левый, кормовой правый и муринг (ленивый конец к якорю). Боковой ветер.",
      envType: EnvironmentType.marina,
      startPos: Vector2(150, 60),
      startAngle: 0, // нос яхты направлен вправо
      defaultWindSpeed: 4.0, // ~8 уз боковой ветер
      defaultWindDirection: 0.0, // ветер вдоль причала
      mooringSetup: MooringSetup.linesAndMooring,
      bollardCount: 2,
      mooringAnchorPositionMeters: Vector2(196, 28), // якорь муринга в воде перед слотом (~12м от причала)
      targetAngleDegrees: 90,
      greenZoneWidthInYachtWidths: 2.0, // зона победы = 2 ширины яхты
      bollardPositionFactors: [0.35, 0.65], // кнехты ближе к центру слота
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

    // УРОВЕНЬ 4: швартовка кормой с якорем (сброс якоря + 2 кормовых к причалу)
    LevelConfig(
      id: 4,
      name: "Stern-to with Anchor",
      description: "Drop anchor in the designated zone, back up to the pier, and secure two stern lines.",
      envType: EnvironmentType.marina,
      startPos: Vector2(150, 80),
      startAngle: 0,
      defaultWindSpeed: 3.0,
      defaultWindDirection: 0.0,
      mooringSetup: MooringSetup.linesAndAnchor,
      bollardCount: 2,
      targetAngleDegrees: 90,
      greenZoneWidthInYachtWidths: 2.0,
      bollardPositionFactors: [0.35, 0.65],
      // Зона отдачи якоря немного ближе к причалу (уменьшили Y-координату).
      anchorDropZoneCenterMeters: Vector2(196, 24),
      marinaLayout: [
        BoatPlacement(type: 'boat', width: 3.0, length: 8.0, sprite: 'yacht_small.png', isNoseRight: true),
        BoatPlacement(type: 'boat', width: 4.0, length: 12.0, sprite: 'yacht_medium.png', isNoseRight: false),
        BoatPlacement(type: 'boat', width: 5.0, length: 10.0, sprite: 'yacht_motor.png', isNoseRight: true),
        BoatPlacement(type: 'boat', width: 3.0, length: 8.0, sprite: 'yacht_small.png', isNoseRight: false),
        BoatPlacement(type: 'player_slot'),
        BoatPlacement(type: 'boat', width: 4.0, length: 12.0, sprite: 'yacht_medium.png', isNoseRight: false),
        BoatPlacement(type: 'boat', width: 3.0, length: 9.0, sprite: 'yacht_small.png', isNoseRight: true),
        BoatPlacement(type: 'boat', width: 5.0, length: 10.0, sprite: 'yacht_motor.png', isNoseRight: false),
        BoatPlacement(type: 'boat', width: 4.0, length: 12.0, sprite: 'yacht_medium.png', isNoseRight: true),
        BoatPlacement(type: 'boat', width: 10.0, length: 20.0, sprite: 'yacht_large.png', isNoseRight: true),
      ],
    ),

    // УРОВЕНЬ 5: Baltic style — нос к причалу, корма к сваям (4 конца)
    LevelConfig(
      id: 5,
      name: "Baltic Mooring",
      description: "Moor bow-first between four piles, then secure bow lines to the dock.",
      envType: EnvironmentType.marina,
      startPos: Vector2(190, 60),
      startAngle: -90,
      defaultWindSpeed: 2.0,
      defaultWindDirection: 0.0,
      mooringSetup: MooringSetup.balticStyle,
      bollardCount: 2,
      targetAngleDegrees: -90,
      greenZoneWidthInYachtWidths: 2.0,
      bollardPositionFactors: [0.35, 0.65],
      // Порядок: [aft port, aft starboard, fwd port, fwd starboard]
      // Сваи формируют «коробку» вокруг слота: кормовые сваи дальше от причала, носовые — ближе.
      pilePositionsMeters: [
        Vector2(193, 22), // aft port
        Vector2(199, 22), // aft starboard
        Vector2(193, 10), // fwd port
        Vector2(199, 10), // fwd starboard
      ],
      marinaLayout: [
        BoatPlacement(type: 'boat', width: 3.0, length: 8.0, sprite: 'yacht_small.png', isNoseRight: true),
        BoatPlacement(type: 'boat', width: 4.0, length: 12.0, sprite: 'yacht_medium.png', isNoseRight: false),
        BoatPlacement(type: 'boat', width: 5.0, length: 10.0, sprite: 'yacht_motor.png', isNoseRight: true),
        BoatPlacement(type: 'boat', width: 3.0, length: 8.0, sprite: 'yacht_small.png', isNoseRight: false),
        BoatPlacement(type: 'player_slot'),
        BoatPlacement(type: 'boat', width: 4.0, length: 12.0, sprite: 'yacht_medium.png', isNoseRight: false),
        BoatPlacement(type: 'boat', width: 3.0, length: 9.0, sprite: 'yacht_small.png', isNoseRight: true),
        BoatPlacement(type: 'boat', width: 5.0, length: 10.0, sprite: 'yacht_motor.png', isNoseRight: false),
        BoatPlacement(type: 'boat', width: 4.0, length: 12.0, sprite: 'yacht_medium.png', isNoseRight: true),
        BoatPlacement(type: 'boat', width: 10.0, length: 20.0, sprite: 'yacht_large.png', isNoseRight: true),
      ],
    ),

    // ===== NARROW MARINA =====
    // Компактная раскладка для узких уровней (5 слотов, игрок по центру).
    // Механика швартовки идентична базовому уровню.

    // УРОВЕНЬ 6: Level 1 mechanics (alongside) + Narrow Marina
    LevelConfig(
      id: 6,
      name: 'Narrow Alongside',
      description: 'Navigate a tight channel lined with moored yachts and park alongside.',
      envType: EnvironmentType.marina,
      startPos: Vector2(170, 100),
      startAngle: 0,
      defaultWindSpeed: 6.0,
      defaultWindDirection: 0.0,
      defaultCurrentSpeed: 0.3,
      currentDirection: -1.57,
      mooringSetup: MooringSetup.linesOnly,
      isNarrowMarina: true,
      marinaLayout: _narrowMarinaLayout,
    ),

    // УРОВЕНЬ 7: Level 3 mechanics (stern-to + mooring) + Narrow Marina
    LevelConfig(
      id: 7,
      name: 'Narrow Stern-to Mooring',
      description: 'Thread the channel and moor stern-to with a mooring line.',
      envType: EnvironmentType.marina,
      startPos: Vector2(180, 100),
      startAngle: 0,
      defaultWindSpeed: 5.0,
      defaultWindDirection: 0.0,
      mooringSetup: MooringSetup.linesAndMooring,
      bollardCount: 2,
      bollardPositionFactors: [0.35, 0.65],
      // Якорь муринга задаётся в [YachtMasterGame] напротив зелёной зоны (см. _setupMarinaLayout).
      // Корма к правому вертикальному пирсу: нос влево (forward = (-1,0) → 180°), не 90° как у верхнего причала.
      targetAngleDegrees: 180,
      greenZoneWidthInYachtWidths: 2.0,
      isNarrowMarina: true,
      marinaLayout: _narrowMarinaLayout,
    ),

    // УРОВЕНЬ 8: Level 4 mechanics (stern-to + anchor) + Narrow Marina
    LevelConfig(
      id: 8,
      name: 'Narrow Stern-to Anchor',
      description: 'Drop anchor in the channel, then reverse to pier and secure two stern lines.',
      envType: EnvironmentType.marina,
      startPos: Vector2(180, 100),
      startAngle: 0,
      defaultWindSpeed: 4.0,
      defaultWindDirection: 0.0,
      mooringSetup: MooringSetup.linesAndAnchor,
      bollardCount: 2,
      bollardPositionFactors: [0.35, 0.65],
      // Центр зоны сброса якоря — в [YachtMasterGame] напротив зелёной зоны (см. _setupMarinaLayout).
      targetAngleDegrees: 180,
      greenZoneWidthInYachtWidths: 2.0,
      isNarrowMarina: true,
      marinaLayout: _narrowMarinaLayout,
    ),

    // УРОВЕНЬ 9: Level 5 mechanics (bow-to + 4 piles) + Narrow Marina
    LevelConfig(
      id: 9,
      name: 'Narrow Baltic Mooring',
      description: 'Enter a narrow channel bow-first and secure all four lines to piles.',
      envType: EnvironmentType.marina,
      startPos: Vector2(180, 100),
      startAngle: 0,
      defaultWindSpeed: 3.0,
      defaultWindDirection: 0.0,
      mooringSetup: MooringSetup.balticStyle,
      bollardCount: 2,
      bollardPositionFactors: [0.35, 0.65],
      // Нос к правому понтону (как [startAngle] 0°), не -90° как у ур. 5 с горизонтальным причалом.
      targetAngleDegrees: 0,
      greenZoneWidthInYachtWidths: 2.0,
      // Позиции свай задаются в [YachtMasterGame] по прямоугольнику зелёной зоны узкой марины.
      isNarrowMarina: true,
      marinaLayout: _narrowMarinaLayout,
    ),
  ];

  static final List<BoatPlacement> _narrowMarinaLayout = [

    BoatPlacement(type: 'player_slot'),
  ];
}