import 'dart:math' as math;

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/yacht_player.dart';
import '../components/moored_yacht.dart';
import '../components/dock_component.dart';
import '../components/mooring_anchor_marker.dart';
import '../components/rope_renderer.dart';
import '../components/sea_component.dart';
import '../core/constants.dart';
import '../core/game_events.dart';
import '../core/marina_layout.dart';
import '../core/camera_math.dart';
import '../core/test_logger.dart';
import '../generated/l10n/app_localizations.dart';
import '../model/level_config.dart';
import '../ui/dashboard_base.dart';

class YachtMasterGame extends FlameGame with HasKeyboardHandlerComponents, HasCollisionDetection {
  late YachtPlayer yacht;
  Dock? dock;
  late Sea sea;
  double totalGameTime = 0;

  /// Уведомляет оверлей швартовки о перестройке (после отдачи/приёма концов).
  final ChangeNotifier mooringOverlayNotifier = ChangeNotifier();

  void _refreshMooringOverlay() {
    yacht.refreshMooringConditions();
    final bool menuVisible = sternPortButtonActive || sternStarboardButtonActive || lazyLineButtonActive ||
        bowButtonActive || sternButtonActive || forwardSpringButtonActive || backSpringButtonActive ||
        anchorDropButtonActive || sternPortButtonActiveAnchor || sternStarboardButtonActiveAnchor;
    if (menuVisible) {
      overlays.remove('MooringMenu');
      overlays.add('MooringMenu');
    }
    mooringOverlayNotifier.notifyListeners();
  }

  /// Локализации для использования в компонентах без BuildContext (устанавливается из GameView).
  AppLocalizations? l10n;

  // Состояние уровня
  LevelConfig? currentLevel;
  LevelConfig? _pendingLevel;
  String statusMessage = "Waiting for command...";
  double activeWindSpeed = 0;
  double activeWindDirection = 0;
  double activeCurrentSpeed = 0;
  double activeCurrentDirection = 0;

  bool bowButtonActive = false;
  bool sternButtonActive = false;
  bool forwardSpringButtonActive = false;
  bool backSpringButtonActive = false;
  bool sternPortButtonActive = false;
  bool sternStarboardButtonActive = false;
  bool lazyLineButtonActive = false;
  bool _victoryTriggered = false;

  List<double> playerBollards = [];
  Rect get playArea => Rect.fromLTWH(0, 0, Constants.playAreaWidth, Constants.playAreaHeight);

  /// Позиция якоря муринга в мире (пиксели). Только для уровня с [MooringSetup.linesAndMooring].
  Vector2? mooringAnchorPositionPixels;

  /// Центр зоны сброса якоря в мировых координатах (пиксели). Только для [MooringSetup.linesAndAnchor].
  Vector2? anchorDropZoneCenterPixels;

  bool anchorDropButtonActive = false;
  bool sternPortButtonActiveAnchor = false;
  bool sternStarboardButtonActiveAnchor = false;

  /// Прямоугольник зелёной зоны (слот причала) в мировых координатах; для уровня 2 — победа при выходе из неё.
  Rect? _greenZoneRect;

  // В начало класса YachtMasterGame
  double _lastWindMult = 1.0;
  double _lastWindDirection = 0.0;
  double _lastCurrentSpeed = 0.0;
  double _lastCurrentDirection = 0.0;
  bool _lastIsRightHanded = true;

  double _pendingWind = 1.0;
  double _pendingWindDirection = 0.0;
  double _pendingCurrentSpeed = 0.0;
  double _pendingCurrentDirection = 0.0;
  bool _pendingRightHanded = true;

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    // totalGameTime — это переменная, которую мы добавили для отслеживания игрового времени

    if (event is KeyDownEvent) {
      // В новом API KeyDownEvent всегда означает ПЕРВОЕ нажатие (не повтор)
      TestLogger.logEvent('DOWN', event.logicalKey, totalGameTime, yacht);
    } else if (event is KeyUpEvent) {
      TestLogger.logEvent('UP', event.logicalKey, totalGameTime, yacht);
    }

    return super.onKeyEvent(event, keysPressed);
  }

  @override
  Color backgroundColor() => const Color(0xFF3E2723);

  @override
  Future<void> onLoad() async {
    // 1. Сначала стандартная настройка систем
    camera.viewport = FixedResolutionViewport(resolution: Vector2(1280, 720));
// Яхта чуть ниже центра. Это даст обзор и не даст ей "утонуть" в Dashboard
    camera.viewfinder.anchor = const Anchor(0.5, 0.65);
    camera.viewport.add(DashboardBase());

    // 2. ЕСЛИ у нас есть запланированный уровень — запускаем его
    if (_pendingLevel != null) {
      startLevel(
        _pendingLevel!,
        windMult: _pendingWind,
        windDirectionRad: _pendingWindDirection,
        currentSpeed: _pendingCurrentSpeed,
        currentDirectionRad: _pendingCurrentDirection,
        isRightHanded: _pendingRightHanded,
      );
    }
  }

  /// Подготовка запуска с экрана настроек уровня.
  void prepareStart(
    LevelConfig config, {
    required double windMult,
    double windDirectionRad = 0.0,
    double currentSpeed = 0.0,
    double currentDirectionRad = 0.0,
    bool propellerRightHanded = true,
  }) {
    _pendingLevel = config;
    _pendingWind = windMult;
    _pendingWindDirection = windDirectionRad;
    _pendingCurrentSpeed = currentSpeed;
    _pendingCurrentDirection = currentDirectionRad;
    _pendingRightHanded = propellerRightHanded;
  }

  // --- ЛОГИКА ЗАПУСКА УРОВНЯ ---
  void startLevel(
    LevelConfig config, {
    required double windMult,
    double windDirectionRad = 0.0,
    double currentSpeed = 0.0,
    double currentDirectionRad = 0.0,
    required bool isRightHanded,
  }) {
    currentLevel = config;
    _lastWindMult = windMult;
    _lastWindDirection = windDirectionRad;
    _lastCurrentSpeed = currentSpeed;
    _lastCurrentDirection = currentDirectionRad;
    _lastIsRightHanded = isRightHanded;

    _victoryTriggered = false;
    statusMessage = "";
    bowButtonActive = false;
    sternButtonActive = false;
    forwardSpringButtonActive = false;
    backSpringButtonActive = false;
    sternPortButtonActive = false;
    sternStarboardButtonActive = false;
    lazyLineButtonActive = false;

    world.removeAll(world.children);

    yacht = YachtPlayer(startAngleDegrees: config.startAngle);

    activeWindSpeed = config.defaultWindSpeed * windMult;
    activeWindDirection = windDirectionRad;
    activeCurrentSpeed = currentSpeed;
    activeCurrentDirection = currentDirectionRad;
    Constants.propType = isRightHanded ? PropellerType.rightHanded : PropellerType.leftHanded;

    _buildEnvironment(config);

    mooringAnchorPositionPixels = config.mooringAnchorPositionMeters != null
        ? config.mooringAnchorPositionMeters! * Constants.pixelRatio
        : null;

    anchorDropZoneCenterPixels = config.anchorDropZoneCenterMeters != null
        ? config.anchorDropZoneCenterMeters! * Constants.pixelRatio
        : null;
    anchorDropButtonActive = false;
    sternPortButtonActiveAnchor = false;
    sternStarboardButtonActiveAnchor = false;

    yacht.position = config.startPos * Constants.pixelRatio;
    yacht.onGameEvent = _onPlayerEvent;
    world.add(yacht);

    world.add(RopeRenderer());
    //if (mooringAnchorPositionPixels != null) {
     // world.add(MooringAnchorMarker(position: mooringAnchorPositionPixels!));
      //
   // }

    // Начальная камера (без плавности)
    const double dockY = 0;
    double distancePixels = (yacht.position.y - dockY).abs();
    double initialZoom = CameraMath.targetZoomSmart(distancePixels);
    camera.viewfinder.zoom = initialZoom;
    double worldHeight = CameraMath.worldHeightAtZoom(initialZoom);
    camera.viewfinder.position = Vector2(yacht.position.x, CameraMath.targetCameraY(dockY, worldHeight));
    camera.viewfinder.anchor = Anchor.center;

    if (config.startWithAllLinesSecured && dock != null && playerBollards.length >= 4) {
      _attachAllFourMooringLines();
    }

    // ВАЖНО: Убеждаемся, что движок работает
    resumeEngine();
  }

  void _buildEnvironment(LevelConfig config) {
    // Фоновое море
    sea = Sea(size: Vector2(playArea.width, playArea.height));
    sea.position = Vector2(playArea.left, playArea.top);
    sea.priority = -15;
    world.add(sea);

    // Текстура стола под бумагой
    world.add(RectangleComponent(
      size: Vector2(Constants.tableSize, Constants.tableSize),
      position: Vector2(Constants.tableOffsetX, Constants.tableOffsetY),
      paint: Paint()..color = const Color(0xFF3E2723),
      priority: -20,
    ));

    // Выбор строителя в зависимости от типа уровня
    switch (config.envType) {
      case EnvironmentType.marina:
        _setupMarinaLayout(config);
        break;
      case EnvironmentType.river:
        _setupRiverLayout(config);
        break;
      case EnvironmentType.openSea:
        _setupOpenSeaLayout(config);
        break;
    }
  }

  void _setupMarinaLayout(LevelConfig config) {
    _greenZoneRect = null;
    final bool sternToLayout = config.mooringSetup.hasMooring || config.mooringSetup.hasAnchor;
    final double slipWidthMeters = sternToLayout ? 8.0 : 15.0;
    final params = MarinaLayoutParams(slotCount: config.marinaLayout.length, slipWidthMeters: slipWidthMeters);
    final double dockWidth = params.dockWidthPixels;
    final double dockX = MarinaLayout.dockX(dockWidth, playArea.width);

    playerBollards.clear();
    playerBollards.addAll(MarinaLayout.playerBollardXPositions(
      config.marinaLayout,
      params.slipStepPixels,
      params.edgePaddingPixels,
      mooringLinesCount: config.mooringLinesCount,
      bollardCount: config.bollardCount,
      bollardPositionFactors: config.bollardPositionFactors,
    ));

    dock = Dock(
      bollardXPositions: playerBollards,
      position: Vector2(dockX, playArea.top),
      size: Vector2(dockWidth, Constants.dockHeightPixels),
    );
    dock!.priority = -5;
    world.add(dock!);

    final double dockBottomY = dock!.position.y + dock!.size.y;

    for (int i = 0; i < config.marinaLayout.length; i++) {
      final p = config.marinaLayout[i];
      final double posX = MarinaLayout.slotCenterX(
        dockX, params.edgePaddingPixels, params.slipStepPixels, i,
      );

      if (p.type == 'player_slot') {
        _addParkingMarker(Vector2(posX, dockBottomY), params.slipStepPixels, config);
        if (anchorDropZoneCenterPixels != null) {
          _addAnchorDropZoneMarker(anchorDropZoneCenterPixels!);
        }
      } else {
        final bool sternTo = sternToLayout;
        double offsetFromDockPx = (p.width * Constants.pixelRatio) / 2 + 2;  // лагом: половина ширины
        if (sternTo) {
          offsetFromDockPx = (p.length * Constants.pixelRatio) / 2 + 2;  // кормой: половина длины, чтобы корма не заходила на пирс
        }
        final moored = MooredYacht(
          position: Vector2(posX, dockBottomY + offsetFromDockPx),
          spritePath: p.sprite ?? 'yacht_medium.png',
          lengthInMeters: p.length,
          widthInMeters: p.width,
          isNoseRight: p.isNoseRight,
        );
        if (sternTo) {
          moored.angle = math.pi / 2; // кормой к причалу (нос в марину)
        }
        world.add(moored);
      }
    }
  }

  void _setupRiverLayout(LevelConfig config) {
    updateStatus(l10n?.statusRiverFlow(config.defaultCurrentSpeed.toStringAsFixed(1)) ?? 'River flow: ${config.defaultCurrentSpeed} kts');
  }

  void _setupOpenSeaLayout(LevelConfig config) {
    dock = null;
    updateStatus(l10n?.statusHighSeas ?? 'High seas. Maintain position.');
  }

  // --- ИГРОВОЙ ЦИКЛ ---

  void _onPlayerEvent(GameEvent event) {
    if (event is CrashEvent) {
      onGameOver(event.message);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    totalGameTime += dt;
    _updateSmartCamera(dt);

    if (dock != null) {
      double distanceToDock = yacht.position.y.abs();
      double targetZoom = CameraMath.targetZoomFromDistanceToDock(distanceToDock);
      camera.viewfinder.zoom += (targetZoom - camera.viewfinder.zoom) * dt * 2.0;
      camera.viewfinder.anchor = Anchor.topCenter;
      camera.viewfinder.position = Vector2(yacht.position.x, 0);
    }

    _handleInput(dt);
    _checkVictoryCondition();
    _checkOutOfBounds();
  }

  void _updateSmartCamera(double dt) {
    if (dock == null) return;

    camera.viewfinder.anchor = Anchor.topCenter;
    double distancePixels = (yacht.position.y - dock!.position.y).abs();
    if (distancePixels < 1) distancePixels = 1;
    double targetZoom = CameraMath.targetZoomSmart(distancePixels);
    camera.viewfinder.zoom += (targetZoom - camera.viewfinder.zoom) * dt * CameraMath.zoomLerpSpeed;
    camera.viewfinder.zoom = camera.viewfinder.zoom.clamp(CameraMath.zoomMin, CameraMath.zoomMax);

    double currentWorldHeight = CameraMath.worldHeightAtZoom(camera.viewfinder.zoom);
    double targetY = CameraMath.targetCameraY(dock!.position.y, currentWorldHeight);
    camera.viewfinder.position = Vector2(yacht.position.x, targetY);
  }

  void _handleInput(double dt) {
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    if (keys.contains(LogicalKeyboardKey.keyW)) yacht.targetThrottle += Constants.inputThrottleRate * dt;
    if (keys.contains(LogicalKeyboardKey.keyS)) yacht.targetThrottle -= Constants.inputThrottleRate * dt;
    if (keys.contains(LogicalKeyboardKey.keyA)) yacht.targetRudderAngle -= Constants.inputRudderRate * dt;
    if (keys.contains(LogicalKeyboardKey.keyD)) yacht.targetRudderAngle += Constants.inputRudderRate * dt;

    yacht.targetThrottle = yacht.targetThrottle.clamp(-1.0, 1.0);
    yacht.targetRudderAngle = yacht.targetRudderAngle.clamp(-1.0, 1.0);

    if (keys.contains(LogicalKeyboardKey.space)) {
      yacht.targetThrottle = 0;
      yacht.targetRudderAngle = 0;
    }
  }

  // --- СОСТОЯНИЯ (ПОБЕДА / ПРОИГРЫШ) ---

  void _checkVictoryCondition() {
    if (_victoryTriggered) return;
    final LevelConfig? config = currentLevel;

    // Уровень 2: победа — отшвартоваться (отдать все концы) и покинуть зелёную зону.
    if (config?.startWithAllLinesSecured == true && _greenZoneRect != null) {
      final bool allReleased = yacht.bowMooredTo == null &&
          yacht.sternMooredTo == null &&
          yacht.forwardSpringMooredTo == null &&
          yacht.backSpringMooredTo == null;
      final bool outsideZone = !_greenZoneRect!.contains(yacht.position.toOffset());
      if (allReleased && outsideZone) {
        _victoryTriggered = true;
        pauseEngine();
        statusMessage = l10n?.statusMissionAccomplished ?? 'MISSION ACCOMPLISHED';
        debugPrint('Victory triggered (departed from zone)');
        TestLogger.printFinalBlock();
        overlays.add('Victory');
      }
      return;
    }

    // Уровень 3 (швартовка кормой с мурингом): все 3 конца закреплены, угол в допуске, скорость в норме.
    if (config != null &&
        config.mooringSetup.hasMooring &&
        config.targetAngleDegrees != null &&
        yacht.sternPortMooredTo != null &&
        yacht.sternStarboardMooredTo != null &&
        yacht.lazyLineAnchor != null) {
      final double yachtDeg = yacht.angle * (180.0 / math.pi);
      double diff = (yachtDeg - config.targetAngleDegrees!) % 360.0;
      if (diff > 180.0) diff -= 360.0;
      if (diff < -180.0) diff += 360.0;
      final bool angleOk = diff.abs() <= Constants.victoryAngleToleranceDegrees;
      final bool stopped = yacht.velocity.length < Constants.victorySpeedThresholdPixels;
      // DEBUG: показываем состояние проверки победы в статусе
      // final String dbg = 'angle=${yachtDeg.toStringAsFixed(1)}° diff=${diff.toStringAsFixed(1)}° speed=${yacht.velocity.length.toStringAsFixed(2)}';
      // if (!angleOk || !stopped) {
      //   updateStatus(dbg);
      // }
      if (angleOk && stopped) {
        _victoryTriggered = true;
        pauseEngine();
        statusMessage = l10n?.statusMissionAccomplished ?? 'MISSION ACCOMPLISHED';
        debugPrint('Victory triggered (Level 3 stern-to mooring)');
        TestLogger.printFinalBlock();
        overlays.add('Victory');
      }
      return;
    }

    // Уровень 4 (швартовка кормой с якорем): якорь сброшен, оба кормовых, перпендикуляр, остановка.
    if (config != null &&
        config.mooringSetup.hasAnchor &&
        config.targetAngleDegrees != null &&
        yacht.isAnchorDropped &&
        yacht.sternPortMooredTo != null &&
        yacht.sternStarboardMooredTo != null) {
      final double yachtDeg = yacht.angle * (180.0 / math.pi);
      double diff = (yachtDeg - config.targetAngleDegrees!) % 360.0;
      if (diff > 180.0) diff -= 360.0;
      if (diff < -180.0) diff += 360.0;
      final bool angleOk = diff.abs() <= Constants.victoryAngleToleranceDegrees;
      final bool stopped = yacht.velocity.length < Constants.victorySpeedThresholdPixels;
      if (angleOk && stopped) {
        _victoryTriggered = true;
        pauseEngine();
        statusMessage = l10n?.statusMissionAccomplished ?? 'MISSION ACCOMPLISHED';
        debugPrint('Victory triggered (Level 4 stern-to with anchor)');
        TestLogger.printFinalBlock();
        overlays.add('Victory');
      }
      return;
    }

    // Уровень 1 (и др.): победа — пришвартоваться и остановиться.
    bool moored = yacht.bowMooredTo != null && yacht.sternMooredTo != null;
    bool stopped = yacht.velocity.length < Constants.victorySpeedThresholdPixels;

    if (moored && stopped) {
      _victoryTriggered = true;
      pauseEngine();
      statusMessage = l10n?.statusMissionAccomplished ?? 'MISSION ACCOMPLISHED';
      debugPrint('Victory triggered');
      TestLogger.printFinalBlock();
      overlays.add('Victory');
    }
  }

  void _checkOutOfBounds() {
    if (!playArea.contains(yacht.position.toOffset())) {
      onGameOver("Vessel left the operations area");
    }
  }

  void onGameOver(String reason) {
    pauseEngine();
    statusMessage = l10n != null ? '${l10n!.statusFailed}: $reason' : 'FAILED: $reason';
    overlays.add('GameOver');
  }

  void updateStatus(String msg) {
    statusMessage = msg;
  }

  void _attachAllFourMooringLines() {
    final bollardY = dock!.position.y + (dock!.size.y * Dock.bollardYFactor);
    final bollards = playerBollards.map((x) => Vector2(dock!.position.x + x, bollardY)).toList();
    if (bollards.length < 4) return;

    // Небольшой слак (запас), чтобы канаты не были в натяжении при старте и не дёргали яхту.
    const double slackPixels = 5.0;

    yacht.bowMooredTo = bollards[0];
    yacht.bowRopeRestLength = yacht.bowWorldPosition.distanceTo(bollards[0]) + slackPixels;
    yacht.forwardSpringMooredTo = bollards[1];
    yacht.forwardSpringRestLength = yacht.forwardSpringWorldPosition.distanceTo(bollards[1]) + slackPixels;
    yacht.backSpringMooredTo = bollards[2];
    yacht.backSpringRestLength = yacht.backSpringWorldPosition.distanceTo(bollards[2]) + slackPixels;
    yacht.sternMooredTo = bollards[3];
    yacht.sternRopeRestLength = yacht.sternWorldPosition.distanceTo(bollards[3]) + slackPixels;
  }

  void _addParkingMarker(Vector2 pos, double slipWidth, LevelConfig config) {
    final double zoneWidth = config.greenZoneWidthInYachtWidths != null
        ? yacht.size.y * config.greenZoneWidthInYachtWidths!
        : slipWidth * 0.9;
    final markerSize = Vector2(zoneWidth, yacht.size.x * 1.2);
    _greenZoneRect = Rect.fromLTWH(
      pos.x - markerSize.x / 2,
      pos.y,
      markerSize.x,
      markerSize.y,
    );
    world.add(RectangleComponent(
      position: pos,
      size: markerSize,
      anchor: Anchor.topCenter,
      paint: Paint()..color = Colors.green.withValues(alpha: 0.4)..style = PaintingStyle.stroke..strokeWidth = 3,
      priority: -1,
    ));
    world.add(RectangleComponent(
      position: pos,
      size: markerSize,
      anchor: Anchor.topCenter,
      paint: Paint()..color = Colors.green.withValues(alpha: 0.1),
      priority: -2,
    ));
  }

  void _addAnchorDropZoneMarker(Vector2 center) {
    final double radius = Constants.anchorDropZoneMarkerRadiusPixels;
    world.add(CircleComponent(
      position: center,
      radius: radius,
      anchor: Anchor.center,
      paint: Paint()
        ..color = Colors.green.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill,
      priority: -2,
    ));
    world.add(CircleComponent(
      position: center,
      radius: radius,
      anchor: Anchor.center,
      paint: Paint()
        ..color = Colors.green.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
      priority: -1,
    ));
  }

  // Швартовка: закрепить конец у тумбы. Уровень 1: носовой — передний кнехт [1], кормовой — задний [0].
  void moerBow() {
    if (dock == null || !yacht.canMoerBow) return;
    final int lineIndex = (currentLevel?.id == 1 && playerBollards.length == 2)
        ? 1  // передний кнехт (со стороны носа)
        : 0;
    _performMooring(lineIndex: lineIndex, isBow: true, isStern: false);
  }

  void moerStern() {
    if (dock == null || !yacht.canMoerStern) return;
    final int lineIndex = (currentLevel?.id == 1 && playerBollards.length == 2)
        ? 0  // задний кнехт (со стороны кормы)
        : playerBollards.length - 1;
    _performMooring(lineIndex: lineIndex, isBow: false, isStern: true);
  }

  void moerForwardSpring() {
    if (dock == null || !yacht.canMoerForwardSpring || playerBollards.length < 4) return;
    _performMooring(lineIndex: 1, isBow: false, isStern: false, isForwardSpring: true);
  }

  void moerBackSpring() {
    if (dock == null || !yacht.canMoerBackSpring || playerBollards.length < 4) return;
    _performMooring(lineIndex: 2, isBow: false, isStern: false, isBackSpring: true);
  }

  /// Кормовой левый (порт) — на левый кнехт слота [0]; кормовой правый (старборд) — на правый [1].
  void moerSternPort() {
    if (dock == null || !yacht.canMoerSternPort || playerBollards.length < 2) return;
    final bollardY = dock!.position.y + (dock!.size.y * Dock.bollardYFactor);
    // Левый борт (порт) → левый кнехт слота [0].
    final Vector2 target = Vector2(dock!.position.x + playerBollards[0], bollardY);
    yacht.sternPortMooredTo = target;
    yacht.sternPortRestLength = yacht.sternLeftWorld.distanceTo(target);
    //updateStatus(l10n?.statusSternSecured ?? 'Stern port secured');
    _refreshMooringOverlay();
  }

  void moerSternStarboard() {
    if (dock == null || !yacht.canMoerSternStarboard || playerBollards.length < 2) return;
    final bollardY = dock!.position.y + (dock!.size.y * Dock.bollardYFactor);
    // Правый борт (старборд) → правый кнехт слота [1].
    final Vector2 target = Vector2(dock!.position.x + playerBollards[1], bollardY);
    yacht.sternStarboardMooredTo = target;
    yacht.sternStarboardRestLength = yacht.sternRightWorld.distanceTo(target);
    //updateStatus(l10n?.statusSternSecured ?? 'Stern starboard secured');
    _refreshMooringOverlay();
  }

  void moerLazyLine() {
    if (mooringAnchorPositionPixels == null) return;
    if (yacht.lazyLineAnchor != null) return;
    yacht.lazyLineAnchor = mooringAnchorPositionPixels;
    yacht.lazyLineRestLength = yacht.bowTipWorldPosition.distanceTo(mooringAnchorPositionPixels!);
    //updateStatus(l10n?.statusBowSecured ?? 'Mooring line secured');
    _refreshMooringOverlay();
  }

  void releaseSternPort() {
    yacht.sternPortMooredTo = null;
    yacht.sternPortRestLength = null;
    //updateStatus(l10n?.statusSternReleased ?? 'Stern port released');
    _refreshMooringOverlay();
  }

  void releaseSternStarboard() {
    yacht.sternStarboardMooredTo = null;
    yacht.sternStarboardRestLength = null;
    //updateStatus(l10n?.statusSternReleased ?? 'Stern starboard released');
    _refreshMooringOverlay();
  }

  void releaseLazyLine() {
    yacht.lazyLineAnchor = null;
    yacht.lazyLineRestLength = null;
    //updateStatus(l10n?.statusBowReleased ?? 'Mooring line released');
    _refreshMooringOverlay();
  }

  void releaseBow() {
    yacht.bowMooredTo = null;
    yacht.bowRopeRestLength = null;
    //updateStatus(l10n?.statusBowReleased ?? 'Bow line released');
    _refreshMooringOverlay();
  }

  void releaseStern() {
    yacht.sternMooredTo = null;
    yacht.sternRopeRestLength = null;
    //updateStatus(l10n?.statusSternReleased ?? 'Stern line released');
    _refreshMooringOverlay();
  }

  void releaseForwardSpring() {
    yacht.forwardSpringMooredTo = null;
    yacht.forwardSpringRestLength = null;
    //updateStatus(l10n?.statusForwardSpringReleased ?? 'Forward spring released');
    _refreshMooringOverlay();
  }

  void releaseBackSpring() {
    yacht.backSpringMooredTo = null;
    yacht.backSpringRestLength = null;
    //updateStatus(l10n?.statusBackSpringReleased ?? 'Back spring released');
    _refreshMooringOverlay();
  }

  void _performMooring({
    required int lineIndex,
    required bool isBow,
    required bool isStern,
    bool isForwardSpring = false,
    bool isBackSpring = false,
  }) {
    final bollardY = dock!.position.y + (dock!.size.y * Dock.bollardYFactor);
    final bollards = playerBollards.map((x) => Vector2(dock!.position.x + x, bollardY)).toList();
    if (lineIndex < 0 || lineIndex >= bollards.length) return;

    Vector2 target = bollards[lineIndex];
    if (isBow) {
      yacht.bowMooredTo = target;
      yacht.bowRopeRestLength = yacht.bowWorldPosition.distanceTo(target);
      updateStatus(l10n?.statusBowSecured ?? 'Bow line secured');
    } else if (isStern) {
      yacht.sternMooredTo = target;
      yacht.sternRopeRestLength = yacht.sternWorldPosition.distanceTo(target);
      updateStatus(l10n?.statusSternSecured ?? 'Stern line secured');
    } else if (isForwardSpring) {
      yacht.forwardSpringMooredTo = target;
      yacht.forwardSpringRestLength = yacht.forwardSpringWorldPosition.distanceTo(target);
      updateStatus(l10n?.statusForwardSpringSecured ?? 'Forward spring secured');
    } else if (isBackSpring) {
      yacht.backSpringMooredTo = target;
      yacht.backSpringRestLength = yacht.backSpringWorldPosition.distanceTo(target);
      updateStatus(l10n?.statusBackSpringSecured ?? 'Back spring secured');
    }
    _refreshMooringOverlay();
  }

  void resetGame() {
    if (currentLevel == null) return;

    // 1. Убираем все всплывающие окна
    overlays.removeAll(['GameOver', 'Victory', 'MooringMenu']);

    // 2. Перезапускаем уровень с сохраненными настройками
    startLevel(
      currentLevel!,
      windMult: _lastWindMult,
      windDirectionRad: _lastWindDirection,
      currentSpeed: _lastCurrentSpeed,
      currentDirectionRad: _lastCurrentDirection,
      isRightHanded: _lastIsRightHanded,
    );

    //updateStatus(l10n?.statusLevelRestarted ?? 'Level Restarted');
  }

  void showMooringButtons(bool bow, bool stern, [bool forwardSpring = false, bool backSpring = false]) {
    if (bowButtonActive == bow && sternButtonActive == stern &&
        forwardSpringButtonActive == forwardSpring && backSpringButtonActive == backSpring) return;

    bowButtonActive = bow;
    sternButtonActive = stern;
    forwardSpringButtonActive = forwardSpring;
    backSpringButtonActive = backSpring;

    if (bowButtonActive || sternButtonActive || forwardSpringButtonActive || backSpringButtonActive) {
      overlays.remove('MooringMenu');
      overlays.add('MooringMenu');
    } else {
      overlays.remove('MooringMenu');
    }
    mooringOverlayNotifier.notifyListeners();
  }

  void showMooringButtonsThreeLines(bool sternPort, bool sternStarboard, bool lazyLine) {
    if (sternPortButtonActive == sternPort && sternStarboardButtonActive == sternStarboard &&
        lazyLineButtonActive == lazyLine) return;

    sternPortButtonActive = sternPort;
    sternStarboardButtonActive = sternStarboard;
    lazyLineButtonActive = lazyLine;

    if (sternPortButtonActive || sternStarboardButtonActive || lazyLineButtonActive) {
      overlays.remove('MooringMenu');
      overlays.add('MooringMenu');
    } else {
      overlays.remove('MooringMenu');
    }
    mooringOverlayNotifier.notifyListeners();
  }

  void hideMooringButtons() {
    final bool anyActive = bowButtonActive || sternButtonActive ||
        forwardSpringButtonActive || backSpringButtonActive ||
        sternPortButtonActive || sternStarboardButtonActive || lazyLineButtonActive ||
        anchorDropButtonActive || sternPortButtonActiveAnchor || sternStarboardButtonActiveAnchor;
    if (!anyActive) return;
    overlays.remove('MooringMenu');
    bowButtonActive = false;
    sternButtonActive = false;
    forwardSpringButtonActive = false;
    backSpringButtonActive = false;
    sternPortButtonActive = false;
    sternStarboardButtonActive = false;
    lazyLineButtonActive = false;
    anchorDropButtonActive = false;
    sternPortButtonActiveAnchor = false;
    sternStarboardButtonActiveAnchor = false;
    mooringOverlayNotifier.notifyListeners();
  }

  /// Проверяет, находится ли центр яхты в зоне сброса якоря.
  bool isYachtInAnchorDropZone() {
    if (anchorDropZoneCenterPixels == null) return false;
    final double radiusPixels = Constants.anchorDropZoneRadiusMeters * Constants.pixelRatio;
    return yacht.position.distanceTo(anchorDropZoneCenterPixels!) < radiusPixels;
  }

  /// Сбросить якорь (уровень 4). Фиксирует позицию якоря в текущей позиции носа.
  void dropAnchor() {
    if (yacht.isAnchorDropped) return;
    if (!isYachtInAnchorDropZone()) {
      updateStatus(l10n?.statusAnchorGetCloser ?? 'Enter the green zone to drop anchor');
      return;
    }
    yacht.isAnchorDropped = true;
    yacht.anchorPosition = yacht.bowTipWorldPosition.clone();
    updateStatus(l10n?.statusAnchorDropped ?? 'Anchor dropped!');
    _refreshMooringOverlay();
  }

  /// Управление кнопками швартовки для уровня 4 (якорь + 2 кормовых).
  void showMooringButtonsAnchor(bool sternPort, bool sternStarboard, bool anchorDrop) {
    if (sternPortButtonActiveAnchor == sternPort &&
        sternStarboardButtonActiveAnchor == sternStarboard &&
        anchorDropButtonActive == anchorDrop) return;
    sternPortButtonActiveAnchor = sternPort;
    sternStarboardButtonActiveAnchor = sternStarboard;
    anchorDropButtonActive = anchorDrop;
    if (sternPort || sternStarboard || anchorDrop) {
      overlays.remove('MooringMenu');
      overlays.add('MooringMenu');
    } else {
      overlays.remove('MooringMenu');
    }
    mooringOverlayNotifier.notifyListeners();
  }
}