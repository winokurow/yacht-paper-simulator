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
import '../model/level_config.dart';
import '../ui/dashboard_base.dart';

class YachtMasterGame extends FlameGame with HasKeyboardHandlerComponents, HasCollisionDetection {
  late YachtPlayer yacht;
  Dock? dock;
  late Sea sea;

  // Состояние уровня
  LevelConfig? currentLevel;
  LevelConfig? _pendingLevel;
  String statusMessage = "Waiting for command...";
  double activeWindSpeed = 0;
  double activeCurrentSpeed = 0;
  double activeCurrentDirection = 0;

  bool bowButtonActive = false;
  bool sternButtonActive = false;
  bool _victoryTriggered = false;

  List<double> playerBollards = [];
  final Rect playArea = const Rect.fromLTWH(0, 0, 10000, 10000);

  // В начало класса YachtMasterGame
  double _lastWindMult = 1.0;
  bool _lastIsRightHanded = true;

  double _pendingWind = 1.0;
  bool _pendingRightHanded = true;

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
      startLevel(_pendingLevel!, _pendingWind, _pendingRightHanded);
    }
  }

  // Новый метод для подготовки запуска из диалога
  void prepareStart(LevelConfig config, double wind, bool rightHanded) {
    _pendingLevel = config;
    _pendingWind = wind;
    _pendingRightHanded = rightHanded;
  }

  // --- ЛОГИКА ЗАПУСКА УРОВНЯ ---
  void startLevel(LevelConfig config, double windMult, bool isRightHanded) {
    // Сохраняем для сброса
    currentLevel = config;
    _lastWindMult = windMult;
    _lastIsRightHanded = isRightHanded;

    _victoryTriggered = false;
    statusMessage = "";

    world.removeAll(world.children);

    // Инициализируем яхту
    yacht = YachtPlayer(startAngleDegrees: config.startAngle);

    activeWindSpeed = config.defaultWindSpeed * windMult;
    activeCurrentSpeed = config.defaultCurrentSpeed;
    activeCurrentDirection = config.currentDirection;
    Constants.propType = isRightHanded ? PropellerType.rightHanded : PropellerType.leftHanded;

    _buildEnvironment(config);

    yacht.position = config.startPos * Constants.pixelRatio;
    world.add(yacht);

// 2. МГНОВЕННЫЙ РАСЧЕТ КАМЕРЫ (без плавности)
    final double dockY = 0; // Предполагаем, что причал на Y=0
    final double distancePixels = (yacht.position.y - dockY).abs();

    // Рассчитываем зум так, чтобы яхта была на 80% высоты экрана
    double targetVisibleHeight = distancePixels / 0.8;
    double initialZoom = (720.0 / targetVisibleHeight).clamp(0.12, 0.5);

    // Принудительно задаем параметры без lerp
    camera.viewfinder.zoom = initialZoom;

    double halfWorldHeight = (720.0 / 2) / initialZoom;
    camera.viewfinder.position = Vector2(yacht.position.x, dockY + halfWorldHeight);
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
    // --- НАСТРОЙКИ РАССТОЯНИЙ ---
    const double slipWidthInMeters = 20.0; // БЫЛО 12.0, СТАЛО 20.0 (расстояние между центрами лодок)
    const double edgePaddingInMeters = 25.0; // Свободное место по краям причала

    final double slipStep = slipWidthInMeters * Constants.pixelRatio;
    final double edgePadding = edgePaddingInMeters * Constants.pixelRatio;

    // Общая ширина причала
    final double dockWidth = (slipStep * config.marinaLayout.length) + (edgePadding * 2);
    final double dockX = (playArea.width / 2) - (dockWidth / 2);

    // Обновляем позиции тумб (передаем новый slipWidthInMeters)
    _calculateBollardPositions(dockX, dockWidth, config.marinaLayout, edgePadding, slipWidthInMeters);

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

      // Позиция лодки с учетом широких слипов
      final double posX = dock!.position.x + edgePadding + (i * slipStep) + (slipStep / 2);

      if (p.type == 'player_slot') {
        _addParkingMarker(Vector2(posX, dockBottomY), slipStep);
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
    _updateSmartCamera(dt);

    if (dock != null) {
      // 1. РАССЧИТЫВАЕМ ДИСТАНЦИЮ (в пикселях)
      // Причал у нас на Y = 0 (playArea.top), яхта на Y = yacht.position.y
      double distanceToDock = yacht.position.y.abs();

      // 2. УСТАНАВЛИВАЕМ ЗУМ
      // Мы хотим, чтобы всё расстояние от причала до яхты занимало 85% высоты экрана.
      // Видимая высота мира = Дистанция / 0.85
      double visibleHeight = distanceToDock / 0.85;

      // Защита от слишком сильного приближения у причала (минимум 15 метров обзора)
      if (visibleHeight < 15 * Constants.pixelRatio) {
        visibleHeight = 15 * Constants.pixelRatio;
      }

      // Зум = Разрешение экрана (720) / Видимая высота мира
      double targetZoom = (720.0 / visibleHeight).clamp(0.08, 0.6);

      // Плавный переход зума
      camera.viewfinder.zoom += (targetZoom - camera.viewfinder.zoom) * dt * 2.0;

      // 3. ПОЗИЦИОНИРОВАНИЕ
      // Мы "приклеиваем" камеру к верхнему центру.
      // С Anchor.topCenter позиция Y=0 означает, что верх экрана - это линия причала.
      camera.viewfinder.anchor = Anchor.topCenter;
      camera.viewfinder.position = Vector2(
        yacht.position.x, // Следим за яхтой только по горизонтали
        0,                // Вертикаль замерла на линии причала
      );
    }

    _handleInput(dt);
    _checkVictoryCondition();
    _checkOutOfBounds();

  }

  void _updateSmartCamera(double dt) {
    if (dock == null) return;

    final double viewportHeight = 720.0;
    final double dockY = dock!.position.y;
    final double yachtY = yacht.position.y;

    // Расстояние до причала
    double distancePixels = (yachtY - dockY).abs();

    // 1. ИДЕАЛЬНЫЙ ЗУМ (чтобы яхта всегда была в нижней части)
    // Чем дальше лодка, тем меньше зум.
    // Мы хотим видеть всю дистанцию + 20% запаса снизу
    double targetZoom = viewportHeight / (distancePixels / 0.8);
    targetZoom = targetZoom.clamp(0.12, 0.5);

    // Плавность оставляем только для зума, чтобы не было резких скачков масштаба
    camera.viewfinder.zoom += (targetZoom - camera.viewfinder.zoom) * dt * 2.0;

    // 2. ЖЕСТКАЯ ФИКСАЦИЯ ПРИЧАЛА СВЕРХУ
    // Высота мира, которую мы видим сейчас при текущем зуме
    double currentWorldHeight = viewportHeight / camera.viewfinder.zoom;

    // Чтобы верхний край (DockY) был в 0 пикселей вьюпорта,
    // центр камеры (Viewfinder Position) должен быть ровно посередине видимой высоты
    double targetY = dockY + (currentWorldHeight / 2);

    // Плавное следование по горизонтали за яхтой
    double targetX = yacht.position.x;

    // Устанавливаем позицию (Y — жестко, X — плавно)
    camera.viewfinder.position = Vector2(
        targetX,
        targetY
    );
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

  // --- ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ---
  void _calculateBollardPositions(double dockX, double dockWidth, List<BoatPlacement> layout, double edgePadding, double currentSlipWidth) {
    playerBollards.clear();
    final double slipStep = currentSlipWidth * Constants.pixelRatio;

    for (int i = 0; i < layout.length; i++) {
      if (layout[i].type == 'player_slot') {
        double slotLeftLocal = edgePadding + (i * slipStep);

        // Ставим тумбы чуть шире, так как само место стало огромным
        // Раньше было 0.2 и 0.8, оставим так же — они распределятся по краям 20-метрового слота
        playerBollards.add(slotLeftLocal + (slipStep * 0.2));
        playerBollards.add(slotLeftLocal + (slipStep * 0.8));
        break;
      }
    }
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
    startLevel(currentLevel!, _lastWindMult, _lastIsRightHanded);

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