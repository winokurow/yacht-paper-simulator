import 'dart:math' hide Rectangle;

import 'package:flame/components.dart';
import 'package:flame/experimental.dart' show Rectangle;
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yacht/components/yacht_player.dart';
import '../components/dock_component.dart';
import '../components/sea_component.dart';
import '../core/constants.dart';
import 'dart:math' as math; // Добавляем префикс для math
import 'package:flame/geometry.dart';

import '../ui/dashboard_base.dart';

class YachtMasterGame extends FlameGame with HasKeyboardHandlerComponents, HasCollisionDetection {
  late YachtPlayer yacht;
  late Dock dock;
  late Sea sea;
  String statusMessage = "Ready to moor";
  // Определяем размер игрового поля (например, 3000x2000 пикселей)
  final Rect playArea = const Rect.fromLTWH(0, 0, 2000, 3000);

  @override
  Future<void> onLoad() async {
    debugMode = false;

    // 1. ПАРАМЕТРЫ ПРИЧАЛА
    const double dockWidth = 800.0;
    const double dockHeight = 120.0;
    final double dockX = (playArea.width / 2) - (dockWidth / 2);
    final double dockY = playArea.top + 100; // Отступ от края листа

    // 2. ИНИЦИАЛИЗАЦИЯ ПРИЧАЛА
    dock = Dock(
      position: Vector2(dockX, dockY),
      size: Vector2(dockWidth, dockHeight),
    );
    dock.priority = -5;
    world.add(dock);

    // 3. ИНИЦИАЛИЗАЦИЯ ЯХТЫ
    // Угол -90 градусов (или -pi/2 радианов) — это направление ВВЕРХ (к причалу)
    yacht = YachtPlayer(startAngleDegrees: -90);

    // Позиция: X — строго по центру причала, Y — причал + 50 метров (1500 пикселей)
    final double startY = dock.position.y + dock.size.y + (50 * Constants.pixelRatio);
    yacht.position = Vector2(playArea.width / 2, startY);
    yacht.priority = 10;
    world.add(yacht);

    // 4. ФОН (Добавляем в world, чтобы он масштабировался вместе с игрой)
    world.add(RectangleComponent(
      size: Vector2(10000, 10000),
      position: Vector2(-4000, -3000),
      paint: Paint()..color = const Color(0xFF3E2723), // Твой коричневый стол
      priority: -20,
    ));

    // 2. МОРЕ (Твой лист бумаги Sea)
    // Размещаем его строго в границах playArea
    sea = Sea(size: Vector2(playArea.width, playArea.height));
    sea.position = Vector2(playArea.left, playArea.top);
    sea.priority = -15;
    world.add(sea);

    // 5. НАСТРОЙКА КАМЕРЫ
    camera.follow(yacht);
    camera.viewfinder.anchor = Anchor.center;

    // Ограничиваем камеру границами листа бумаги
    camera.setBounds(Rectangle.fromLTWH(
        playArea.left, playArea.top, playArea.width, playArea.height
    ));

    // В конце метода onLoad
    final dashboard = DashboardBase();
    // Добавляем именно в viewport!
    camera.viewport.add(dashboard);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _applyDynamicZoom(dt);
  }

  void _applyDynamicZoom(double dt) {
    // Вычисляем расстояние между центром яхты и центром причала
    final dockCenter = dock.position + (dock.size / 2);
    final yachtCenter = yacht.position;

    // Добавляем запас (padding), чтобы объекты не были впритык к краям экрана
    double dx = (yachtCenter.x - dockCenter.x).abs() + 600;
    double dy = (yachtCenter.y - dockCenter.y).abs() + 600;

    // Считаем зум исходя из текущего размера экрана
    double zoomX = size.x / dx;
    double zoomY = size.y / dy;

    double targetZoom = min(zoomX, zoomY).clamp(0.4, 1.2);

    // Плавное приближение/удаление
    camera.viewfinder.zoom += (targetZoom - camera.viewfinder.zoom) * 1.5 * dt;
  }

    // Простое управление для теста US 1.1
  @override
  KeyEventResult onKeyEvent(
      KeyEvent event,
      Set<LogicalKeyboardKey> keysPressed,
      ) {
    // Шаг изменения (насколько меняется значение при одном нажатии/удержании)
    // Можно подстроить под себя: чем меньше число, тем плавнее управление
    const double step = 0.01;

    // Мы реагируем только когда клавиши НАЖАТЫ или УДЕРЖИВАЮТСЯ (Repeat)
    if (event is KeyDownEvent || event is KeyRepeatEvent) {

      // ГАЗ (W / S)
      if (keysPressed.contains(LogicalKeyboardKey.keyW)) {
        // Увеличиваем газ и ограничиваем его максимумом 1.0
        yacht.throttle = (yacht.throttle + step).clamp(-1.0, 1.0);
      }
      if (keysPressed.contains(LogicalKeyboardKey.keyS)) {
        // Уменьшаем газ и ограничиваем его минимумом -1.0
        yacht.throttle = (yacht.throttle - step).clamp(-1.0, 1.0);
      }

      // РУЛЬ (A / D)
      if (keysPressed.contains(LogicalKeyboardKey.keyA)) {
        // Поворачиваем влево
        yacht.rudderAngle = (yacht.rudderAngle - step).clamp(-1.0, 1.0);
      }
      if (keysPressed.contains(LogicalKeyboardKey.keyD)) {
        // Поворачиваем вправо
        yacht.rudderAngle = (yacht.rudderAngle + step).clamp(-1.0, 1.0);
      }

      // ДОПОЛНИТЕЛЬНО: Клавиша "Пробел" для быстрой нейтрали и выравнивания руля
      if (keysPressed.contains(LogicalKeyboardKey.space)) {
        yacht.throttle = 0.0;
        yacht.rudderAngle = 0.0;
      }
    }

    return KeyEventResult.handled;
  }
  }