import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:yacht/components/yacht_player.dart';
import '../components/anemometer.dart';
import '../components/dock_component.dart';
import '../components/hud_component.dart';
import '../components/sea_component.dart';
import '../core/constants.dart';

class YachtMasterGame extends FlameGame with HasKeyboardHandlerComponents, HasCollisionDetection {
  late final YachtPlayer yacht;
  String statusMessage = "Ready to moor";
  @override
  Future<void> onLoad() async {
    debugMode = false;
    // 1. ФОН СТОЛА (самый нижний слой)
    final table = RectangleComponent(
      size: Vector2(10000, 10000),
      position: Vector2(-5000, -5000),
      paint: Paint()..color = const Color(0xFFBC8F8F), // Темное дерево
      priority: -10,
    );
    world.add(table);

    // 2. МОРЕ (синяя бумага поверх стола)
    final sea = Sea(size: Vector2(4000, 4000));
    sea.position = Vector2(-2000, -2000);
    world.add(sea);

// 3. ДОБАВЛЯЕМ ПРИЧАЛ
    // Теперь он будет использовать нашу новую логику тайлинга (плитки)
    final dock = Dock(
        position: Vector2(200, 100),
        size: Vector2(800, 60), // Длинный и узкий картонный причал
        );
        dock.priority = -2;
        world.add(dock);

    // 3. Создаем яхту (YachtPlayer)
    yacht = YachtPlayer();

    // Ставим яхту параллельно причалу, ниже его на 10 метров (500 пикселей)
    // И смещаем немного к началу причала
    yacht.position = Vector2(200 / 4, 100 + (10 * Constants.pixelRatio));

    // Угол 0 во Flame — это носом вправо (параллельно нашему причалу)
    yacht.angle = 0;
    dock.priority = 5;
    await world.add(yacht);

    // 4. Камера
    camera.follow(yacht);

    // 5. Интерфейс
    await camera.viewport.add(YachtHud());
    await camera.viewport.add(Anemometer());
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