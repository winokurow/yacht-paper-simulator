import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/yacht_player.dart';
import '../components/MooredYacht.dart';
import '../components/dock_component.dart';
import '../components/sea_component.dart';
import '../core/constants.dart';
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
  bool _victoryTriggered = false;

  List<double> playerBollards = [];
  final Rect playArea = const Rect.fromLTWH(0, 0, 10000, 10000);

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
    world.add(yacht);

// 2. Начальная камера (без плавности)
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
      size: Vector2(10000, 10000),
      position: Vector2(-4000, -3000),
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
    final params = MarinaLayoutParams(slotCount: config.marinaLayout.length);
    final double dockWidth = params.dockWidthPixels;
    final double dockX = MarinaLayout.dockX(dockWidth, playArea.width);

    playerBollards.clear();
    playerBollards.addAll(MarinaLayout.playerBollardXPositions(
      config.marinaLayout,
      params.slipStepPixels,
      params.edgePaddingPixels,
    ));

    dock = Dock(
      bollardXPositions: playerBollards,
      position: Vector2(dockX, playArea.top),
      size: Vector2(dockWidth, 140.0),
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
    // Тут можно добавить берега реки
    updateStatus("River flow detected: ${config.defaultCurrentSpeed} kts");
  }

  void _setupOpenSeaLayout(LevelConfig config) {
    // В открытом море причала нет
    dock = null;
    updateStatus("High seas. Maintain position.");
  }

  // --- ИГРОВОЙ ЦИКЛ ---

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

    double distancePixels = (yacht.position.y - dock!.position.y).abs();
    if (distancePixels < 1) distancePixels = 1;
    double targetZoom = CameraMath.targetZoomSmart(distancePixels);
    camera.viewfinder.zoom += (targetZoom - camera.viewfinder.zoom) * dt * 2.0;
    camera.viewfinder.zoom = camera.viewfinder.zoom.clamp(CameraMath.zoomMin, CameraMath.zoomMax);

    double currentWorldHeight = CameraMath.worldHeightAtZoom(camera.viewfinder.zoom);
    double targetY = CameraMath.targetCameraY(dock!.position.y, currentWorldHeight);
    camera.viewfinder.position = Vector2(yacht.position.x, targetY);
  }

  void _handleInput(double dt) {
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    if (keys.contains(LogicalKeyboardKey.keyW)) yacht.targetThrottle += 0.8 * dt;
    if (keys.contains(LogicalKeyboardKey.keyS)) yacht.targetThrottle -= 0.8 * dt;
    if (keys.contains(LogicalKeyboardKey.keyA)) yacht.targetRudderAngle -= 1.2 * dt;
    if (keys.contains(LogicalKeyboardKey.keyD)) yacht.targetRudderAngle += 1.2 * dt;

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
    bool moored = yacht.bowMooredTo != null && yacht.sternMooredTo != null;
    bool stopped = yacht.velocity.length < (0.2 * Constants.pixelRatio);

    if (moored && stopped) {
      _victoryTriggered = true;
      pauseEngine();
      statusMessage = "MISSION ACCOMPLISHED";
      print('DEBUG: Victory triggered!'); // Добавьте для проверки
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
    statusMessage = "FAILED: $reason";
    overlays.add('GameOver');
  }

  void updateStatus(String msg) {
    statusMessage = msg;
  }

  void _addParkingMarker(Vector2 pos, double slipWidth) {
    final markerSize = Vector2(slipWidth * 0.9, yacht.size.x * 1.2);
    world.add(RectangleComponent(
      position: pos,
      size: markerSize,
      anchor: Anchor.topCenter,
      paint: Paint()..color = Colors.green.withOpacity(0.4)..style = PaintingStyle.stroke..strokeWidth = 3,
      priority: -1,
    ));
    world.add(RectangleComponent(
      position: pos,
      size: markerSize,
      anchor: Anchor.topCenter,
      paint: Paint()..color = Colors.green.withOpacity(0.1),
      priority: -2,
    ));
  }

  // Швартовка
  void moerBow() {
    if (dock == null || !yacht.canMoerBow) return;
    _performMooring(isBow: true);
  }

  void moerStern() {
    if (dock == null || !yacht.canMoerStern) return;
    _performMooring(isBow: false);
  }

  void _performMooring({required bool isBow}) {
    final bollardY = dock!.position.y + (dock!.size.y * Dock.bollardYFactor);
    final bollards = playerBollards.map((x) => Vector2(dock!.position.x + x, bollardY)).toList();
    final currentPos = isBow ? yacht.bowWorldPosition : yacht.sternWorldPosition;

    Vector2 target = bollards.reduce((a, b) => currentPos.distanceTo(a) < currentPos.distanceTo(b) ? a : b);

    if (isBow) {
      yacht.bowMooredTo = target;
      yacht.bowRopeRestLength = yacht.bowWorldPosition.distanceTo(target);
      updateStatus("Bow line secured");
    } else {
      yacht.sternMooredTo = target;
      yacht.sternRopeRestLength = yacht.sternWorldPosition.distanceTo(target);
      updateStatus("Stern line secured");
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

    // 3. Сбрасываем сообщение в интерфейсе
    updateStatus("Level Restarted");
  }

  void showMooringButtons(bool bow, bool stern) {
    // Предотвращаем мерцание: если состояние кнопок не изменилось, ничего не делаем
    if (bowButtonActive == bow && sternButtonActive == stern) return;

    bowButtonActive = bow;
    sternButtonActive = stern;

    // Если хотя бы одна кнопка должна быть видна — показываем оверлей
    if (bowButtonActive || sternButtonActive) {
      // Сначала удаляем старый, чтобы Flutter перерисовал виджет с новыми параметрами
      overlays.remove('MooringMenu');
      overlays.add('MooringMenu');
    } else {
      overlays.remove('MooringMenu');
    }
  }

  void hideMooringButtons() {
    // Если кнопки и так скрыты, выходим
    if (!bowButtonActive && !sternButtonActive) return;

    overlays.remove('MooringMenu');
    bowButtonActive = false;
    sternButtonActive = false;
  }
}