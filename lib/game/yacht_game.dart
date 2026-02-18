import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/yacht_player.dart';
import '../components/moored_yacht.dart';
import '../components/dock_component.dart';
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
  bool _victoryTriggered = false;

  List<double> playerBollards = [];
  Rect get playArea => Rect.fromLTWH(0, 0, Constants.playAreaWidth, Constants.playAreaHeight);

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

    world.removeAll(world.children);

    yacht = YachtPlayer(startAngleDegrees: config.startAngle);

    activeWindSpeed = config.defaultWindSpeed * windMult;
    activeWindDirection = windDirectionRad;
    activeCurrentSpeed = currentSpeed;
    activeCurrentDirection = currentDirectionRad;
    Constants.propType = isRightHanded ? PropellerType.rightHanded : PropellerType.leftHanded;

    _buildEnvironment(config);

    yacht.position = config.startPos * Constants.pixelRatio;
    yacht.onGameEvent = _onPlayerEvent;
    world.add(yacht);

    if (config.startWithAllLinesSecured && dock != null && playerBollards.length >= 4) {
      _attachAllFourMooringLines();
    }

    world.add(RopeRenderer());

    // Начальная камера (без плавности)
    const double dockY = 0;
    double distancePixels = (yacht.position.y - dockY).abs();
    double initialZoom = CameraMath.targetZoomSmart(distancePixels);
    camera.viewfinder.zoom = initialZoom;
    double worldHeight = CameraMath.worldHeightAtZoom(initialZoom);
    camera.viewfinder.position = Vector2(yacht.position.x, CameraMath.targetCameraY(dockY, worldHeight));
    camera.viewfinder.anchor = Anchor.center;

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
    final params = MarinaLayoutParams(slotCount: config.marinaLayout.length);
    final double dockWidth = params.dockWidthPixels;
    final double dockX = MarinaLayout.dockX(dockWidth, playArea.width);

    playerBollards.clear();
    playerBollards.addAll(MarinaLayout.playerBollardXPositions(
      config.marinaLayout,
      params.slipStepPixels,
      params.edgePaddingPixels,
      mooringLinesCount: config.mooringLinesCount,
      bollardCount: config.bollardCount,
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
        _addParkingMarker(Vector2(posX, dockBottomY), params.slipStepPixels);
      } else {
        double boatWidthPx = p.width * Constants.pixelRatio;
        world.add(MooredYacht(
          position: Vector2(posX, dockBottomY + (boatWidthPx / 2) + 2),
          spritePath: p.sprite ?? 'yacht_medium.png',
          lengthInMeters: p.length,
          widthInMeters: p.width,
          isNoseRight: p.isNoseRight,
        ));
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

    yacht.bowMooredTo = bollards[0];
    yacht.bowRopeRestLength = yacht.bowWorldPosition.distanceTo(bollards[0]);
    yacht.forwardSpringMooredTo = bollards[1];
    yacht.forwardSpringRestLength = yacht.forwardSpringWorldPosition.distanceTo(bollards[1]);
    yacht.backSpringMooredTo = bollards[2];
    yacht.backSpringRestLength = yacht.backSpringWorldPosition.distanceTo(bollards[2]);
    yacht.sternMooredTo = bollards[3];
    yacht.sternRopeRestLength = yacht.sternWorldPosition.distanceTo(bollards[3]);
    //updateStatus(l10n?.statusAllLinesSecured ?? 'All lines secured. Release to depart.');
  }

  void _addParkingMarker(Vector2 pos, double slipWidth) {
    final markerSize = Vector2(slipWidth * 0.9, yacht.size.x * 1.2);
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

  // Швартовка: закрепить конец у ближайшей тумбы
  void moerBow() {
    if (dock == null || !yacht.canMoerBow) return;
    _performMooring(lineIndex: 0, isBow: true, isStern: false);
  }

  void moerStern() {
    if (dock == null || !yacht.canMoerStern) return;
    _performMooring(lineIndex: playerBollards.length - 1, isBow: false, isStern: true);
  }

  void moerForwardSpring() {
    if (dock == null || !yacht.canMoerForwardSpring || playerBollards.length < 4) return;
    _performMooring(lineIndex: 1, isBow: false, isStern: false, isForwardSpring: true);
  }

  void moerBackSpring() {
    if (dock == null || !yacht.canMoerBackSpring || playerBollards.length < 4) return;
    _performMooring(lineIndex: 2, isBow: false, isStern: false, isBackSpring: true);
  }

  void releaseBow() {
    yacht.bowMooredTo = null;
    yacht.bowRopeRestLength = null;
    updateStatus(l10n?.statusBowReleased ?? 'Bow line released');
  }

  void releaseStern() {
    yacht.sternMooredTo = null;
    yacht.sternRopeRestLength = null;
    updateStatus(l10n?.statusSternReleased ?? 'Stern line released');
  }

  void releaseForwardSpring() {
    yacht.forwardSpringMooredTo = null;
    yacht.forwardSpringRestLength = null;
    updateStatus(l10n?.statusForwardSpringReleased ?? 'Forward spring released');
  }

  void releaseBackSpring() {
    yacht.backSpringMooredTo = null;
    yacht.backSpringRestLength = null;
    updateStatus(l10n?.statusBackSpringReleased ?? 'Back spring released');
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

    updateStatus(l10n?.statusLevelRestarted ?? 'Level Restarted');
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
  }

  void hideMooringButtons() {
    if (!bowButtonActive && !sternButtonActive && !forwardSpringButtonActive && !backSpringButtonActive) return;
    overlays.remove('MooringMenu');
    bowButtonActive = false;
    sternButtonActive = false;
    forwardSpringButtonActive = false;
    backSpringButtonActive = false;
  }
}