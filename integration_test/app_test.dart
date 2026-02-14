import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yacht/game/yacht_game.dart';

import 'package:yacht/main.dart';
import 'package:yacht/core/constants.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // --- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ---

  YachtMasterGame getGame(WidgetTester tester) {
    final finder = find.byKey(const Key('yacht_game_widget'));
    return (tester.widget(finder) as GameWidget<YachtMasterGame>).game!;
  }

  Future<void> navigateToLevel1(WidgetTester tester) async {
    await tester.pumpWidget(const YachtApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Первый причал'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('В ПУТЬ!'));
    await tester.pump(const Duration(seconds: 1));
  }

  /// ГЛАВНАЯ ФУНКЦИЯ ШАГА: объединяет ожидание, действие и синхронизацию

  Future<void> runStep(

      WidgetTester tester,

      YachtMasterGame game, {

        required double t,

        String? action,

        LogicalKeyboardKey? key,

        required double px, // Координата X

        required double py, // Координата Y

        required double ang, // Угол

        required double vx, // Скорость X

        required double vy, // Скорость Y

      }) async {

// 1. Рассчитываем время до следующего события в игровых секундах

    double timeToWait = t - game.totalGameTime;

    if (timeToWait > 0) {

      const double dt = 1 / 60;

      int steps = (timeToWait / dt).round();

      for (int i = 0; i < steps; i++) {

        game.update(dt);

        await tester.pump(const Duration(milliseconds: 16, microseconds: 666));

      }

    }



// 2. Выполняем нажатие или отпускание клавиши (если они есть в этом шаге)

    if (key != null && action != null) {

      if (action == "DOWN") await tester.sendKeyDownEvent(key);

      if (action == "UP") await tester.sendKeyUpEvent(key);

      await tester.pump();

    }



// 3. ЖЕСТКАЯ СИНХРОНИЗАЦИЯ

// Устанавливаем точные значения из лога, чтобы избежать накопления ошибки

    game.yacht.position = Vector2(px, py);

    game.yacht.angle = ang;

    game.yacht.velocity = Vector2(vx, vy);



    await tester.pump();

  }

  group('Комплексные игровые сценарии', () {

    testWidgets('Сценарий 1: Успешная швартовка (Timeline)', (tester) async {
      await navigateToLevel1(tester);
      final game = getGame(tester);

      // Сброс игрового времени для чистоты теста
      game.totalGameTime = 0;

      // --- НАЧАЛЬНАЯ ТОЧКА (из твоего лога) ---
      game.yacht.position = Vector2(3750.02, 1500.38);
      game.yacht.angle = -0.0006;
      game.yacht.velocity = Vector2(0.01, 0.03);
      await tester.pump();

      // --- ТВОЙ ОБНОВЛЕННЫЙ ЛОГ (Пример перевода в runStep) ---
      // Вставляй сюда данные, которые выдает новый TestLogger.logEvent

      await runStep(tester, game, t: 0.526, action: "DOWN", key: LogicalKeyboardKey.keyW, px: 3750.00, py: 1500.12, ang: 0.0000, vx: 0.00, vy: 0.00);
      await runStep(tester, game, t: 1.586, action: "UP", key: LogicalKeyboardKey.keyW, px: 3757.91, py: 1501.37, ang: -0.0264, vx: 0.84, vy: 0.04);
      await runStep(tester, game, t: 1.887, action: "DOWN", key: LogicalKeyboardKey.keyA, px: 3765.98, py: 1501.61, ang: -0.0335, vx: 1.26, vy: 0.02);
      await runStep(tester, game, t: 3.476, action: "UP", key: LogicalKeyboardKey.keyA, px: 3846.15, py: 1498.26, ang: -0.1520, vx: 2.48, vy: -0.27);
      await runStep(tester, game, t: 10.609, action: "DOWN", key: LogicalKeyboardKey.keyD, px: 4240.82, py: 1250.23, ang: -1.0432, vx: 1.41, vy: -2.24);
      await runStep(tester, game, t: 11.243, action: "UP", key: LogicalKeyboardKey.keyD, px: 4261.68, py: 1213.94, ang: -1.1033, vx: 1.24, vy: -2.32);
      await runStep(tester, game, t: 11.594, action: "DOWN", key: LogicalKeyboardKey.keyD, px: 4272.31, py: 1193.46, ang: -1.1185, vx: 1.19, vy: -2.35);
      await runStep(tester, game, t: 11.774, action: "UP", key: LogicalKeyboardKey.keyD, px: 4277.61, py: 1182.90, ang: -1.1240, vx: 1.17, vy: -2.35);
      await runStep(tester, game, t: 16.068, action: "DOWN", key: LogicalKeyboardKey.keyS, px: 4397.28, py: 928.29, ang: -1.1572, vx: 1.08, vy: -2.39);
      await runStep(tester, game, t: 16.198, action: "UP", key: LogicalKeyboardKey.keyS, px: 4400.75, py: 920.57, ang: -1.1582, vx: 1.07, vy: -2.38);
      await runStep(tester, game, t: 16.912, action: "DOWN", key: LogicalKeyboardKey.keyS, px: 4419.30, py: 879.06, ang: -1.1634, vx: 1.02, vy: -2.29);
      await runStep(tester, game, t: 17.125, action: "UP", key: LogicalKeyboardKey.keyS, px: 4424.65, py: 867.00, ang: -1.1649, vx: 0.99, vy: -2.24);
      await runStep(tester, game, t: 19.875, action: "DOWN", key: LogicalKeyboardKey.keyS, px: 4482.97, py: 731.24, ang: -1.1915, vx: 0.77, vy: -1.86);
      await runStep(tester, game, t: 19.992, action: "UP", key: LogicalKeyboardKey.keyS, px: 4485.20, py: 725.83, ang: -1.1928, vx: 0.76, vy: -1.84);
      await runStep(tester, game, t: 20.225, action: "DOWN", key: LogicalKeyboardKey.keyS, px: 4489.57, py: 715.21, ang: -1.1954, vx: 0.74, vy: -1.80);
      await runStep(tester, game, t: 20.392, action: "UP", key: LogicalKeyboardKey.keyS, px: 4492.60, py: 707.79, ang: -1.1974, vx: 0.72, vy: -1.76);
      await runStep(tester, game, t: 22.939, action: "DOWN", key: LogicalKeyboardKey.keyS, px: 4529.17, py: 614.19, ang: -1.2341, vx: 0.48, vy: -1.31);
      await runStep(tester, game, t: 23.089, action: "UP", key: LogicalKeyboardKey.keyS, px: 4530.96, py: 609.32, ang: -1.2365, vx: 0.47, vy: -1.28);
      await runStep(tester, game, t: 25.063, action: "DOWN", key: LogicalKeyboardKey.keyW, px: 4549.59, py: 556.16, ang: -1.2746, vx: 0.31, vy: -0.93);
      await runStep(tester, game, t: 25.196, action: "UP", key: LogicalKeyboardKey.keyW, px: 4550.61, py: 553.06, ang: -1.2776, vx: 0.30, vy: -0.93);
      await runStep(tester, game, t: 25.697, action: "DOWN", key: LogicalKeyboardKey.keyD, px: 4554.41, py: 541.14, ang: -1.2885, vx: 0.30, vy: -0.97);
      await runStep(tester, game, t: 26.515, action: "UP", key: LogicalKeyboardKey.keyD, px: 4560.60, py: 520.79, ang: -1.2935, vx: 0.30, vy: -1.02);
      await runStep(tester, game, t: 27.500, action: "DOWN", key: LogicalKeyboardKey.keyD, px: 4568.48, py: 495.37, ang: -1.2696, vx: 0.34, vy: -1.04);
      await runStep(tester, game, t: 28.168, action: "UP", key: LogicalKeyboardKey.keyD, px: 4574.33, py: 477.84, ang: -1.2508, vx: 0.36, vy: -1.05);
      await runStep(tester, game, t: 28.923, action: "DOWN", key: LogicalKeyboardKey.keyS, px: 4581.48, py: 457.85, ang: -1.2276, vx: 0.39, vy: -1.06);
      await runStep(tester, game, t: 29.074, action: "UP", key: LogicalKeyboardKey.keyS, px: 4582.97, py: 453.89, ang: -1.2232, vx: 0.39, vy: -1.04);
      await runStep(tester, game, t: 30.326, action: "DOWN", key: LogicalKeyboardKey.keyS, px: 4594.56, py: 424.77, ang: -1.1959, vx: 0.35, vy: -0.84);
      await runStep(tester, game, t: 30.493, action: "UP", key: LogicalKeyboardKey.keyS, px: 4596.01, py: 421.33, ang: -1.1932, vx: 0.34, vy: -0.81);
      await runStep(tester, game, t: 30.990, action: "DOWN", key: LogicalKeyboardKey.keyS, px: 4599.83, py: 412.45, ang: -1.1889, vx: 0.28, vy: -0.64);
      await runStep(tester, game, t: 31.056, action: "UP", key: LogicalKeyboardKey.keyS, px: 4600.29, py: 411.41, ang: -1.1886, vx: 0.27, vy: -0.62);
      await runStep(tester, game, t: 32.104, action: "DOWN", key: LogicalKeyboardKey.keyS, px: 4605.64, py: 399.90, ang: -1.1714, vx: 0.15, vy: -0.29);
      await runStep(tester, game, t: 32.488, action: "UP", key: LogicalKeyboardKey.keyS, px: 4606.67, py: 398.05, ang: -1.1329, vx: 0.06, vy: -0.08);
      await runStep(tester, game, t: 32.968, action: "DOWN", key: LogicalKeyboardKey.keyW, px: 4606.25, py: 399.46, ang: -1.0222, vx: -0.12, vy: 0.28);
      await runStep(tester, game, t: 33.323, action: "UP", key: LogicalKeyboardKey.keyW, px: 4604.54, py: 402.72, ang: -0.9440, vx: -0.23, vy: 0.41);
      await runStep(tester, game, t: 33.774, action: "DOWN", key: LogicalKeyboardKey.keyW, px: 4601.49, py: 407.60, ang: -0.9143, vx: -0.30, vy: 0.45);
      await runStep(tester, game, t: 33.907, action: "UP", key: LogicalKeyboardKey.keyW, px: 4600.48, py: 409.14, ang: -0.9110, vx: -0.30, vy: 0.46);
      await runStep(tester, game, t: 34.291, action: "DOWN", key: LogicalKeyboardKey.keyW, px: 4597.65, py: 413.39, ang: -0.9096, vx: -0.29, vy: 0.43);
      await runStep(tester, game, t: 34.462, action: "UP", key: LogicalKeyboardKey.keyW, px: 4596.46, py: 415.18, ang: -0.9102, vx: -0.27, vy: 0.41);
      await runStep(tester, game, t: 34.825, action: "DOWN", key: LogicalKeyboardKey.keyW, px: 4594.43, py: 418.36, ang: -0.9118, vx: -0.19, vy: 0.31);
      await runStep(tester, game, t: 34.959, action: "UP", key: LogicalKeyboardKey.keyW, px: 4593.86, py: 419.30, ang: -0.9126, vx: -0.16, vy: 0.26);
      await runStep(tester, game, t: 35.326, action: "DOWN", key: LogicalKeyboardKey.keyD, px: 4592.99, py: 420.99, ang: -0.9160, vx: -0.05, vy: 0.12);
      await runStep(tester, game, t: 35.476, action: "UP", key: LogicalKeyboardKey.keyD, px: 4592.92, py: 421.31, ang: -0.9181, vx: -0.00, vy: 0.06);
      await runStep(tester, game, t: 37.267, action: "DOWN", key: LogicalKeyboardKey.keyD, px: 4603.04, py: 410.47, ang: -0.9332, vx: 0.42, vy: -0.50);
      await runStep(tester, game, t: 37.801, action: "UP", key: LogicalKeyboardKey.keyD, px: 4609.27, py: 402.90, ang: -0.9276, vx: 0.51, vy: -0.62);
      await runStep(tester, game, t: 39.270, action: "DOWN", key: LogicalKeyboardKey.keyS, px: 4631.89, py: 375.69, ang: -0.8952, vx: 0.71, vy: -0.83);
      await runStep(tester, game, t: 39.471, action: "UP", key: LogicalKeyboardKey.keyS, px: 4635.44, py: 371.54, ang: -0.8897, vx: 0.71, vy: -0.82);
      await runStep(tester, game, t: 41.457, action: "DOWN", key: LogicalKeyboardKey.keyS, px: 4667.48, py: 336.33, ang: -0.8519, vx: 0.60, vy: -0.63);
      await runStep(tester, game, t: 41.591, action: "UP", key: LogicalKeyboardKey.keyS, px: 4669.47, py: 334.26, ang: -0.8501, vx: 0.59, vy: -0.61);
      await runStep(tester, game, t: 42.426, action: "DOWN", key: LogicalKeyboardKey.keyS, px: 4680.27, py: 323.28, ang: -0.8441, vx: 0.46, vy: -0.46);
      await runStep(tester, game, t: 42.709, action: "UP", key: LogicalKeyboardKey.keyS, px: 4683.28, py: 320.34, ang: -0.8363, vx: 0.38, vy: -0.37);
      await runStep(tester, game, t: 43.361, action: "DOWN", key: LogicalKeyboardKey.keyW, px: 4687.39, py: 316.94, ang: -0.7132, vx: 0.14, vy: -0.07);
      await runStep(tester, game, t: 43.578, action: "UP", key: LogicalKeyboardKey.keyW, px: 4687.98, py: 316.74, ang: -0.6662, vx: 0.09, vy: -0.02);
      await runStep(tester, game, t: 43.728, action: "DOWN", key: LogicalKeyboardKey.keyW, px: 4688.30, py: 316.70, ang: -0.6515, vx: 0.08, vy: -0.00);
      await runStep(tester, game, t: 43.861, action: "UP", key: LogicalKeyboardKey.keyW, px: 4688.56, py: 316.70, ang: -0.6462, vx: 0.08, vy: -0.00);
      await runStep(tester, game, t: 44.508, action: "DOWN", key: LogicalKeyboardKey.keyW, px: 4690.15, py: 316.49, ang: -0.6556, vx: 0.11, vy: -0.02);
      await runStep(tester, game, t: 44.659, action: "UP", key: LogicalKeyboardKey.keyW, px: 4690.62, py: 316.37, ang: -0.6593, vx: 0.13, vy: -0.04);
      await runStep(tester, game, t: 46.265, action: "DOWN", key: LogicalKeyboardKey.keyS, px: 4702.57, py: 309.36, ang: -0.6784, vx: 0.43, vy: -0.29);
      await runStep(tester, game, t: 46.432, action: "UP", key: LogicalKeyboardKey.keyS, px: 4704.42, py: 308.13, ang: -0.6789, vx: 0.45, vy: -0.30);
      await runStep(tester, game, t: 46.908, action: "DOWN", key: LogicalKeyboardKey.keyS, px: 4709.54, py: 304.72, ang: -0.6812, vx: 0.42, vy: -0.28);
      await runStep(tester, game, t: 47.058, action: "UP", key: LogicalKeyboardKey.keyS, px: 4711.08, py: 303.71, ang: -0.6819, vx: 0.40, vy: -0.26);
      await runStep(tester, game, t: 47.772, action: "DOWN", key: LogicalKeyboardKey.keyS, px: 4716.76, py: 300.21, ang: -0.6750, vx: 0.25, vy: -0.14);
      await runStep(tester, game, t: 47.922, action: "UP", key: LogicalKeyboardKey.keyS, px: 4717.62, py: 299.75, ang: -0.6700, vx: 0.21, vy: -0.11);
      await runStep(tester, game, t: 48.373, action: "DOWN", key: LogicalKeyboardKey.keyW, px: 4719.01, py: 299.36, ang: -0.5874, vx: 0.05, vy: 0.02);
      await runStep(tester, game, t: 48.573, action: "UP", key: LogicalKeyboardKey.keyW, px: 4719.13, py: 299.58, ang: -0.5479, vx: 0.01, vy: 0.05);
      await runStep(tester, game, t: 48.653, action: "DOWN", key: LogicalKeyboardKey.keyW, px: 4719.15, py: 299.69, ang: -0.5395, vx: 0.01, vy: 0.06);
      await runStep(tester, game, t: 48.803, action: "UP", key: LogicalKeyboardKey.keyW, px: 4719.17, py: 299.91, ang: -0.5321, vx: 0.01, vy: 0.06);
      await runStep(tester, game, t: 49.266, action: "DOWN", key: LogicalKeyboardKey.keyW, px: 4719.67, py: 300.33, ang: -0.5369, vx: 0.07, vy: 0.02);
      await runStep(tester, game, t: 49.417, action: "UP", key: LogicalKeyboardKey.keyW, px: 4720.01, py: 300.37, ang: -0.5405, vx: 0.10, vy: 0.00);
      await runStep(tester, game, t: 50.731, action: "DOWN", key: LogicalKeyboardKey.keyS, px: 4730.07, py: 296.22, ang: -0.5568, vx: 0.48, vy: -0.24);
      await runStep(tester, game, t: 50.882, action: "UP", key: LogicalKeyboardKey.keyS, px: 4731.92, py: 295.30, ang: -0.5570, vx: 0.50, vy: -0.25);
      await runStep(tester, game, t: 51.332, action: "DOWN", key: LogicalKeyboardKey.keyS, px: 4737.62, py: 292.44, ang: -0.5580, vx: 0.51, vy: -0.26);
      await runStep(tester, game, t: 51.503, action: "UP", key: LogicalKeyboardKey.keyS, px: 4739.79, py: 291.35, ang: -0.5583, vx: 0.50, vy: -0.25);
      await runStep(tester, game, t: 52.626, action: "DOWN", key: LogicalKeyboardKey.keyS, px: 4751.01, py: 286.15, ang: -0.5427, vx: 0.32, vy: -0.13);
      await runStep(tester, game, t: 52.743, action: "UP", key: LogicalKeyboardKey.keyS, px: 4751.89, py: 285.79, ang: -0.5409, vx: 0.29, vy: -0.12);
      await runStep(tester, game, t: 53.377, action: "DOWN", key: LogicalKeyboardKey.keyW, px: 4755.06, py: 284.93, ang: -0.4351, vx: 0.12, vy: -0.00);
      await runStep(tester, game, t: 53.561, action: "UP", key: LogicalKeyboardKey.keyW, px: 4755.53, py: 284.98, ang: -0.4049, vx: 0.10, vy: 0.01);
      await runStep(tester, game, t: 53.661, action: "DOWN", key: LogicalKeyboardKey.keyW, px: 4755.80, py: 285.01, ang: -0.3984, vx: 0.11, vy: 0.01);
      await runStep(tester, game, t: 53.795, action: "UP", key: LogicalKeyboardKey.keyW, px: 4756.19, py: 285.05, ang: -0.3954, vx: 0.12, vy: 0.01);
      await runStep(tester, game, t: 56.153, action: "DOWN", key: LogicalKeyboardKey.keyS, px: 4776.64, py: 279.77, ang: -0.4205, vx: 0.53, vy: -0.17);
      await runStep(tester, game, t: 56.253, action: "UP", key: LogicalKeyboardKey.keyS, px: 4777.97, py: 279.34, ang: -0.4208, vx: 0.53, vy: -0.18);
      await runStep(tester, game, t: 56.587, action: "DOWN", key: LogicalKeyboardKey.keyS, px: 4782.36, py: 277.88, ang: -0.4222, vx: 0.52, vy: -0.17);
      await runStep(tester, game, t: 56.737, action: "UP", key: LogicalKeyboardKey.keyS, px: 4784.28, py: 277.25, ang: -0.4220, vx: 0.50, vy: -0.16);
      await runStep(tester, game, t: 57.184, action: "DOWN", key: LogicalKeyboardKey.keyS, px: 4789.27, py: 275.70, ang: -0.4161, vx: 0.40, vy: -0.12);
      await runStep(tester, game, t: 57.317, action: "UP", key: LogicalKeyboardKey.keyS, px: 4790.54, py: 275.35, ang: -0.4063, vx: 0.36, vy: -0.10);
      await runStep(tester, game, t: 57.697, action: "DOWN", key: LogicalKeyboardKey.keyW, px: 4793.27, py: 274.78, ang: -0.3385, vx: 0.23, vy: -0.03);
      await runStep(tester, game, t: 57.847, action: "UP", key: LogicalKeyboardKey.keyW, px: 4794.05, py: 274.72, ang: -0.3078, vx: 0.20, vy: -0.01);
      await runStep(tester, game, t: 58.332, action: "DOWN", key: LogicalKeyboardKey.keyW, px: 4796.17, py: 274.78, ang: -0.2794, vx: 0.16, vy: 0.02);
      await runStep(tester, game, t: 58.461, action: "UP", key: LogicalKeyboardKey.keyW, px: 4796.66, py: 274.84, ang: -0.2777, vx: 0.15, vy: 0.02);
      await runStep(tester, game, t: 61.291, action: "DOWN", key: LogicalKeyboardKey.keyS, px: 4815.24, py: 273.40, ang: -0.3285, vx: 0.34, vy: -0.05);
      await runStep(tester, game, t: 61.391, action: "UP", key: LogicalKeyboardKey.keyS, px: 4816.10, py: 273.27, ang: -0.3294, vx: 0.34, vy: -0.05);
      await runStep(tester, game, t: 62.109, action: "DOWN", key: LogicalKeyboardKey.keyS, px: 4821.51, py: 272.53, ang: -0.3255, vx: 0.27, vy: -0.03);
      await runStep(tester, game, t: 62.280, action: "UP", key: LogicalKeyboardKey.keyS, px: 4822.58, py: 272.44, ang: -0.3214, vx: 0.23, vy: -0.02);
      await runStep(tester, game, t: 62.760, action: "DOWN", key: LogicalKeyboardKey.keyW, px: 4824.38, py: 272.60, ang: -0.2344, vx: 0.08, vy: 0.04);
      await runStep(tester, game, t: 62.927, action: "UP", key: LogicalKeyboardKey.keyW, px: 4824.63, py: 272.79, ang: -0.2011, vx: 0.05, vy: 0.05);
      await runStep(tester, game, t: 62.977, action: "DOWN", key: LogicalKeyboardKey.keyW, px: 4824.69, py: 272.85, ang: -0.1950, vx: 0.05, vy: 0.05);
      await runStep(tester, game, t: 63.144, action: "UP", key: LogicalKeyboardKey.keyW, px: 4824.93, py: 273.06, ang: -0.1852, vx: 0.07, vy: 0.05);
      await runStep(tester, game, t: 67.618, action: "DOWN", key: LogicalKeyboardKey.keyD, px: 4880.40, py: 268.25, ang: -0.2071, vx: 0.77, vy: -0.10);
      await runStep(tester, game, t: 67.768, action: "UP", key: LogicalKeyboardKey.keyD, px: 4883.32, py: 267.86, ang: -0.2060, vx: 0.78, vy: -0.10);
      await runStep(tester, game, t: 71.237, action: "DOWN", key: LogicalKeyboardKey.keyS, px: 4958.85, py: 258.75, ang: -0.1631, vx: 0.93, vy: -0.10);
      await runStep(tester, game, t: 71.370, action: "UP", key: LogicalKeyboardKey.keyS, px: 4961.96, py: 258.44, ang: -0.1611, vx: 0.92, vy: -0.09);
      // ... и так далее по всем событиям DOWN/UP из консоли ...



      // Даем яхте успокоиться после последнего шага лога
      //await tester.pump(const Duration(seconds: 1));

      print('--- Поиск кнопки НОСОВОЙ ---');
      final bowButton = find.text('ПОДАТЬ НОСОВОЙ');

      // Ждем появления кнопки, если она не появилась мгновенно
      await tester.pumpAndSettle();

      if (tester.any(bowButton)) {
        await tester.tap(bowButton);
        print('Нажат НОСОВОЙ');

        // ВАЖНО: Даем время физике и UI обновиться
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        final sternButton = find.text('ПОДАТЬ КОРМОВОЙ');
        if (tester.any(sternButton)) {
          await tester.tap(sternButton);
          print('Нажат КОРМОВОЙ');
        } else {
          // Если кнопки нет, пробуем чуть-чуть подождать и подтолкнуть физику
          print('Кнопка КОРМОВОЙ не найдена, пробуем подождать...');
          game.update(0.5);
          await tester.pumpAndSettle();
          await tester.tap(find.text('ПОДАТЬ КОРМОВОЙ'));
        }

        await tester.pumpAndSettle(const Duration(seconds: 1));
        expect(find.text('MISSION ACCOMPLISHED'), findsOneWidget);
      }
    });

    testWidgets('Сценарий 2: Крушение (носовой удар)', (tester) async {
      await navigateToLevel1(tester);
      final game = getGame(tester);
      game.yacht.position = Vector2(game.yacht.position.x, 5 * Constants.pixelRatio);
      game.yacht.velocity = Vector2(0, -150);

      for (int i = 0; i < 40; i++) {
        game.update(1/60);
        await tester.pump(const Duration(milliseconds: 16));
        if (game.overlays.isActive('GameOver')) break;
      }
      expect(game.overlays.isActive('GameOver'), isTrue);
    });
  });
}