import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/experimental.dart' show Rectangle;
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yacht/components/yacht_player.dart';
import '../components/MooredYacht.dart';
import '../components/dock_component.dart';
import '../components/sea_component.dart';
import '../core/constants.dart';

import '../ui/dashboard_base.dart';

class YachtMasterGame extends FlameGame with HasKeyboardHandlerComponents, HasCollisionDetection {
  late YachtPlayer yacht;
  late Dock dock;
  late Sea sea;
  String statusMessage = "Ready to moor";
  bool bowButtonActive = false;
  bool sternButtonActive = false;
  bool _victoryTriggered = false;

  final List<Map<String, dynamic>> marinaConfig = [
    {
      'type': 'boat',
      'width': 3.0,     // Узкий катер
      'length': 8.0,
      'sprite': 'yacht_small.png',
      'hitboxType': 'pointy', // Острый нос
      'isNoseRight': true,    // Нос смотрит вправо
    },
    {
      'type': 'boat',
      'width': 4.0,     // Средняя парусная яхта
      'length': 12.0,
      'sprite': 'yacht_medium.png',
      'hitboxType': 'pointy', // Острый нос
      'isNoseRight': false,    // Нос смотрит вправо
    },
    {
      'type': 'boat',
      'width': 5.0,     // Большая моторная яхта
      'length': 10.0,
      'sprite': 'yacht_motor.png',
      'hitboxType': 'pointy', // Острый нос
      'isNoseRight': true,    // Нос смотрит вправо
    },
    {
      'type': 'player_slot' // Твое свободное место (индекс 3)
    },
    {
      'type': 'boat',
      'width': 4.0,
      'length': 12.0,
      'sprite': 'yacht_medium.png',
      'hitboxType': 'pointy', // Острый нос
      'isNoseRight': false,    // Нос смотрит вправо
    },
    {
      'type': 'boat',
      'width': 3.0,
      'length': 9.0,
      'sprite': 'yacht_small.png',
      'hitboxType': 'pointy', // Острый нос
      'isNoseRight': true,    // Нос смотрит вправо
    },
    {
      'type': 'boat',
      'width': 10.0,     // Самый крупный объект в марине
      'length': 22.0,
      'sprite': 'yacht_large.png',
      'hitboxType': 'square', // Острый нос
      'isNoseRight': true,    // Нос смотрит вправо
    },
  ];
  List<double> playerBollards = [];
  final Rect playArea = const Rect.fromLTWH(0, 0, 2000, 3000);

  @override
  Future<void> onLoad() async {
    debugMode = true;
    camera.viewfinder.anchor = Anchor.center;

    // 1. ПАРАМЕТРЫ ПРИЧАЛА
    const double dockWidth = 1200.0;
    const double dockHeight = 120.0;
    final double dockX = (playArea.width / 2) - (dockWidth / 2);
    final double dockY = playArea.top;

    // 2. СНАЧАЛА СЧИТАЕМ ТУМБЫ
    _calculateBollardPositions(dockX, dockWidth); // Новый вспомогательный метод

    // 3. ТЕПЕРЬ ИНИЦИАЛИЗИРУЕМ ПРИЧАЛ С ГОТОВЫМ СПИСКОМ
    dock = Dock(
      position: Vector2(dockX, dockY),
      size: Vector2(dockWidth, dockHeight),
      bollardXPositions: playerBollards, // Теперь список уже не пуст!
    );
    dock.priority = -5;
    world.add(dock);

    // 3. ИНИЦИАЛИЗАЦИЯ ЯХТЫ
    yacht = YachtPlayer(startAngleDegrees: -90);
    final double startY = dock.position.y + dock.size.y + (50 * Constants.pixelRatio);
    yacht.position = Vector2(playArea.width / 2, startY);
    yacht.priority = 10;
    world.add(yacht);

    // 4. ФОН (Стол)
    world.add(RectangleComponent(
      size: Vector2(10000, 10000),
      position: Vector2(-4000, -3000),
      paint: Paint()..color = const Color(0xFF3E2723),
      priority: -20,
    ));

    // 5. МОРЕ (Лист бумаги)
    sea = Sea(size: Vector2(playArea.width, playArea.height));
    sea.position = Vector2(playArea.left, playArea.top);
    sea.priority = -15;
    world.add(sea);

    // 6. НАСТРОЙКА МАРИНЫ (Пришвартованные яхты)
    _setupMarina();

    // 7. НАСТРОЙКА КАМЕРЫ
    camera.viewfinder.anchor = Anchor.center;
    camera.setBounds(Rectangle.fromLTWH(
        playArea.left, playArea.top, playArea.width, playArea.height
    ));

    // 8. ИНТЕРФЕЙС
    final dashboard = DashboardBase();
    camera.viewport.add(dashboard);
  }

  void _setupMarina() {
    final int totalSlips = marinaConfig.length;
    final double slipStep = (dock.size.x / totalSlips).roundToDouble();
    final double dockBottomY = (dock.position.y + dock.size.y).roundToDouble();

    for (int i = 0; i < totalSlips; i++) {
      final config = marinaConfig[i];
      final double posX = (dock.position.x + (i * slipStep) + (slipStep / 2)).roundToDouble();

      if (config['type'] == 'player_slot') {
        _addParkingMarker(Vector2(posX, dockBottomY), slipStep);
        continue; // Тумбы уже добавлены в onLoad!
      }

      // Логика добавления MooredYacht...
      double boatWidthPx = (config['width'] * Constants.pixelRatio).roundToDouble();
      double posY = (dockBottomY + (boatWidthPx / 2) + 2).roundToDouble();

      world.add(MooredYacht(
        position: Vector2(posX, posY),
        spritePath: config['sprite'],
        lengthInMeters: config['length'],
        widthInMeters: config['width'],
        hitboxType: config['hitboxType'] ?? 'pointy',
        isNoseRight: config['isNoseRight'] ?? true,
      ));
    }
  }

  void _addParkingMarker(Vector2 pos, double slipWidth) {
    // 1. Настраиваем размеры
    final double markerWidth = slipWidth * 0.9;
    // Высота теперь равна длине яхты + небольшой запас, но не бесконечная
    final double markerHeight = yacht.size.x * 1.2;

    // 2. Рассчитываем позицию (верхний край рамки = нижний край причала)
    final double topOfMarkerY = dock.position.y + dock.size.y;
    final Vector2 markerPos = Vector2(pos.x, topOfMarkerY);

    // 3. Внешняя зеленая рамка
    final marker = RectangleComponent(
      position: markerPos,
      size: Vector2(markerWidth, markerHeight),
      anchor: Anchor.topCenter, // Привязка к верхнему центру
      paint: Paint()
        ..color = Colors.green.withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
      priority: -1,
    );

    // 4. Внутренняя заливка
    final fill = RectangleComponent(
      position: markerPos,
      size: marker.size,
      anchor: Anchor.topCenter,
      paint: Paint()..color = Colors.green.withOpacity(0.15),
      priority: -2,
    );

    world.add(marker);
    world.add(fill);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 1. Динамический зум (уже с округлением)
    _applyDynamicZoom(dt);

    // 2. РУЧНОЕ СЛЕДОВАНИЕ КАМЕРЫ С ПИКСЕЛЬНОЙ ПРИВЯЗКОЙ
    // Мы берем позицию яхты и округляем её до целых чисел.
    // Это гарантирует, что камера не стоит "между пикселями".
    camera.viewfinder.position = Vector2(
      yacht.position.x.roundToDouble(),
      yacht.position.y.roundToDouble(),
    );

    _checkVictoryCondition();
  }

  void _applyDynamicZoom(double dt) {
    final dockCenter = dock.position + (dock.size / 2);
    final yachtCenter = yacht.position;

    // Рассчитываем желаемый зум на основе расстояния
    double dx = (yachtCenter.x - dockCenter.x).abs() + 600;
    double dy = (yachtCenter.y - dockCenter.y).abs() + 600;

    double zoomX = size.x / dx;
    double zoomY = size.y / dy;

    // Целевой зум
    double targetZoom = math.min(zoomX, zoomY).clamp(0.4, 1.2);

    // ПЛАВНОСТЬ: Используем lerp для мягкого перехода
    double currentZoom = camera.viewfinder.zoom;
    double newZoom = currentZoom + (targetZoom - currentZoom) * 1.5 * dt;

    // ЗАЩИТА: Округляем до 3 знаков после запятой.
    // Этого достаточно для плавности глазу, но это убирает бесконечные микро-колебания.
    camera.viewfinder.zoom = (newZoom * 1000).roundToDouble() / 1000;
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    const double throttleStep = 0.02;
    const double rudderStep = 0.05;

    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      if (keysPressed.contains(LogicalKeyboardKey.keyW)) {
        yacht.throttle = (yacht.throttle + throttleStep).clamp(-1.0, 1.0);
      }
      if (keysPressed.contains(LogicalKeyboardKey.keyS)) {
        yacht.throttle = (yacht.throttle - throttleStep).clamp(-1.0, 1.0);
      }
      if (keysPressed.contains(LogicalKeyboardKey.keyA)) {
        yacht.targetRudderAngle = (yacht.targetRudderAngle - rudderStep).clamp(-1.0, 1.0);
      }
      if (keysPressed.contains(LogicalKeyboardKey.keyD)) {
        yacht.targetRudderAngle = (yacht.targetRudderAngle + rudderStep).clamp(-1.0, 1.0);
      }
      if (keysPressed.contains(LogicalKeyboardKey.space)) {
        yacht.throttle = 0.0;
        yacht.targetRudderAngle = 0.0;
      }
    }
    return KeyEventResult.handled;
  }

  void onOutOfBounds() {
    pauseEngine(); // Останавливаем игру, чтобы лодка не уплывала дальше
    overlays.add('GameOver');
  }

  void showMooringButtons(bool bow, bool stern) {
    // Если ничего не изменилось, не тратим ресурсы на перерисовку
    if (bowButtonActive == bow && sternButtonActive == stern) return;

    bowButtonActive = bow;
    sternButtonActive = stern;

    // Если хотя бы одна кнопка должна гореть
    if (bowButtonActive || sternButtonActive) {
      // Перезапускаем оверлей, чтобы Flutter перестроил Row с двумя кнопками
      overlays.remove('MooringMenu');
      overlays.add('MooringMenu');
    } else {
      overlays.remove('MooringMenu');
    }
  }

  void hideMooringButtons() {
    overlays.remove('MooringMenu');
  }

// Внутри класса YachtMasterGame (lib/game/yacht_game.dart)

  void moerBow() {
    if (yacht.canMoerBow) {
      final bollardY = dock.position.y + dock.size.y;
      List<Vector2> bollards = dock.bollardXPositions
          .map((x) => Vector2(dock.position.x + x, bollardY))
          .toList();

      Vector2 targetBollard = bollards.reduce((a, b) =>
      yacht.bowWorldPosition.distanceTo(a) < yacht.bowWorldPosition.distanceTo(b) ? a : b);

      // Считаем, какой борт ближе
      double distRight = yacht.bowRightWorld.distanceTo(targetBollard);
      double distLeft = yacht.bowLeftWorld.distanceTo(targetBollard);

      yacht.bowMooredTo = targetBollard;

      // ГЕОМЕТРИЯ:
      // X: 0.4 (10% от края носа)
      // Y: 0.35 (это 50% - 15% отступа от края борта)
      double mooringX = yacht.size.x * 0.4;
      double mooringY = yacht.size.y * 0.35;

      yacht.bowAnchorPointLocal = distRight < distLeft
          ? Vector2(mooringX, mooringY)  // Правый борт (внутри)
          : Vector2(mooringX, -mooringY); // Левый борт (внутри)
    }
  }

  void moerStern() {
    if (yacht.canMoerStern) {
      final bollardY = dock.position.y + dock.size.y;
      List<Vector2> bollards = dock.bollardXPositions
          .map((x) => Vector2(dock.position.x + x, bollardY))
          .toList();

      Vector2 targetBollard = bollards.reduce((a, b) =>
      yacht.sternWorldPosition.distanceTo(a) < yacht.sternWorldPosition.distanceTo(b) ? a : b);

      double distRight = yacht.sternRightWorld.distanceTo(targetBollard);
      double distLeft = yacht.sternLeftWorld.distanceTo(targetBollard);

      yacht.sternMooredTo = targetBollard;

      // Аналогично для кормы
      double mooringX = -yacht.size.x * 0.4;
      double mooringY = yacht.size.y * 0.35;

      yacht.sternAnchorPointLocal = distRight < distLeft
          ? Vector2(mooringX, mooringY)
          : Vector2(mooringX, -mooringY);
    }
  }

  void _calculateBollardPositions(double dockX, double dockWidth) {
    playerBollards.clear();
    final int totalSlips = marinaConfig.length;
    final double slipStep = dockWidth / totalSlips;

    for (int i = 0; i < totalSlips; i++) {
      if (marinaConfig[i]['type'] == 'player_slot') {
        // Рассчитываем положение слота относительно начала причала (локально)
        double slotLeftLocal = i * slipStep;

        // Ставим тумбы на 20% и 80% ширины слота
        playerBollards.add(slotLeftLocal + (slipStep * 0.2));
        playerBollards.add(slotLeftLocal + (slipStep * 0.8));
        break; // Нашли наш слот, выходим
      }
    }
  }

  void _checkVictoryCondition() {
    if (_victoryTriggered) return;

    // Условия победы:
    // 1. Подан носовой
    // 2. Подан кормовой
    // 3. Скорость почти нулевая (меньше 0.2 м/с)
    bool moored = yacht.bowMooredTo != null && yacht.sternMooredTo != null;
    bool stopped = yacht.velocity.length < (0.2 * Constants.pixelRatio);

    if (moored && stopped) {
      _victoryTriggered = true;
      _showVictory();
    }
  }

  void _showVictory() {
    pauseEngine(); // Останавливаем физику
    overlays.add('Victory');
  }

// Не забудь обновить метод сброса!
  void resetGame() {
    overlays.remove('GameOver');
    overlays.remove('Victory'); // Убираем окно победы
    _victoryTriggered = false; // Сбрасываем флаг
    yacht.resetToInitialState();
    resumeEngine();
  }

  void onGameOver(String reason) {
    // Останавливаем игру
    pauseEngine();

    // Сохраняем причину для отображения в UI (необязательно, если в UI фиксированный текст)
    statusMessage = reason;

    // Показываем оверлей проигрыша
    // Убедись, что 'GameOver' зарегистрирован в main.dart
    overlays.add('GameOver');
  }
}