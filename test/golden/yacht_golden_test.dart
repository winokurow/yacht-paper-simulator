import 'dart:math' as math;

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yacht/components/dock_component.dart';
import 'package:yacht/components/yacht_player.dart';
import 'package:yacht/core/constants.dart';
import 'package:yacht/game/game_view.dart';
import 'package:yacht/game/yacht_game.dart';
import 'package:yacht/model/level_config.dart';

// --- Поддержка golden-тестов: mock и тестовая игра с фейковым спрайтом ---
class MockYachtMasterGame extends Mock implements YachtMasterGame {}

class GoldenTestYachtGame extends YachtMasterGame {
  GoldenTestYachtGame(this._mock);

  final MockYachtMasterGame _mock;

  @override
  Future<void> onLoad() async {
    camera.viewport = FixedResolutionViewport(resolution: Vector2(1280, 720));
    camera.viewfinder.anchor = const Anchor(0.5, 0.65);
    yacht = YachtPlayer(startAngleDegrees: 0);
    world.add(yacht);
  }

  @override
  Future<Sprite> loadSprite(String path, {Vector2? srcSize, Vector2? srcPosition}) =>
      _mock.loadSprite(path, srcSize: srcSize, srcPosition: srcPosition);

  @override
  void onGameOver(String reason) {}
  @override
  void showMooringButtons(bool bow, bool stern, [bool forwardSpring = false, bool backSpring = false]) {}
  @override
  void hideMooringButtons() {}
  @override
  double get activeCurrentSpeed => 0.0;
  @override
  double get activeCurrentDirection => 0.0;
  @override
  Dock? get dock => _mock.dock;
}

Future<Sprite> _createFakeSprite() async {
  final image = await generateImage(2, 2);
  return Sprite(image);
}

/// Устройства для визуального регресса (iPhone 13-подобный и планшет).
final _goldenDevices = [
  Device.phone,
  Device.tabletLandscape,
];

/// Игра постоянно обновляется — не ждём settle, только один кадр.
Future<void> _pumpOnce(WidgetTester tester) => tester.pump();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockYachtMasterGame mockGame;
  late Sprite fakeSprite;

  setUpAll(() async {
    fakeSprite = await _createFakeSprite();
  });

  setUp(() {
    mockGame = MockYachtMasterGame();
    when(() => mockGame.loadSprite(any())).thenAnswer((_) async => fakeSprite);
    when(() => mockGame.activeCurrentSpeed).thenReturn(0.0);
    when(() => mockGame.activeCurrentDirection).thenReturn(0.0);
    when(() => mockGame.dock).thenReturn(Dock(
      bollardXPositions: [],
      position: Vector2.zero(),
      size: Vector2(100, 140),
    ));
  });

  group('Golden: YachtPlayer (paper style)', () {
    testGoldens('Rotation & Shadow: яхта 45°, перо руля на максимуме', (tester) async {
      final game = GoldenTestYachtGame(mockGame);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'monospace'),
          home: GameWidget<YachtMasterGame>(
            game: game,
            overlayBuilderMap: {
              'Victory': (_, __) => const SizedBox(),
              'GameOver': (_, __) => const SizedBox(),
              'MooringMenu': (_, __) => const SizedBox(),
            },
          ),
        ),
      );
      await tester.runAsync(() => game.ready());
      await tester.pump();

      final yacht = game.yacht;
      yacht.position = Vector2(640, 360);
      yacht.angle = 45 * math.pi / 180;
      yacht.targetRudderAngle = 1.0;
      for (int i = 0; i < 50; i++) game.update(0.016);
      await tester.pump();

      await multiScreenGolden(
        tester,
        'yacht_rotation_shadow',
        devices: _goldenDevices,
        customPump: _pumpOnce,
      );
    });

    testGoldens('Mooring Ropes: натянутая линия + ослабленная кривая Безье', (tester) async {
      final game = GoldenTestYachtGame(mockGame);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'monospace'),
          home: GameWidget<YachtMasterGame>(
            game: game,
            overlayBuilderMap: {
              'Victory': (_, __) => const SizedBox(),
              'GameOver': (_, __) => const SizedBox(),
              'MooringMenu': (_, __) => const SizedBox(),
            },
          ),
        ),
      );
      await tester.runAsync(() => game.ready());
      await tester.pump();

      final yacht = game.yacht;
      yacht.position = Vector2(640, 360);
      yacht.bowMooredTo = yacht.localToParent(Vector2(yacht.size.x * 0.5, 0)) + Vector2(150, 0);
      yacht.bowRopeRestLength = 10;
      yacht.sternMooredTo = yacht.sternWorldPosition + Vector2(15, 15);
      yacht.sternRopeRestLength = 100;
      await tester.pump();

      await multiScreenGolden(
        tester,
        'yacht_mooring_ropes',
        devices: _goldenDevices,
        customPump: _pumpOnce,
      );
    });
  });

  group('Golden: Dashboard (UI)', () {
    testGoldens('Dashboard: полный вперед (рычаг вверху, спидометр макс)', (tester) async {
      final game = YachtMasterGame();
      game.prepareStart(
        GameLevels.allLevels.first,
        windMult: 1.0,
        currentSpeed: 0,
        currentDirectionRad: 0,
        propellerRightHanded: true,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'monospace', primarySwatch: Colors.brown),
          home: GameView(game: game),
        ),
      );
      await tester.runAsync(() => game.ready());
      await tester.pump();

      game.yacht.velocity = Vector2(Constants.maxSpeedMeters, 0);
      game.yacht.targetThrottle = 1.0;
      for (int i = 0; i < 80; i++) game.update(0.016);
      await tester.pump();

      await multiScreenGolden(
        tester,
        'dashboard_full_forward',
        devices: _goldenDevices,
        customPump: _pumpOnce,
      );
    });

    testGoldens('Dashboard: полный назад', (tester) async {
      final game = YachtMasterGame();
      game.prepareStart(
        GameLevels.allLevels.first,
        windMult: 1.0,
        currentSpeed: 0,
        currentDirectionRad: 0,
        propellerRightHanded: true,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'monospace', primarySwatch: Colors.brown),
          home: GameView(game: game),
        ),
      );
      await tester.runAsync(() => game.ready());
      await tester.pump();

      game.yacht.velocity = Vector2(-Constants.maxSpeedMeters * 0.5, 0);
      game.yacht.targetThrottle = -1.0;
      for (int i = 0; i < 80; i++) game.update(0.016);
      await tester.pump();

      await multiScreenGolden(
        tester,
        'dashboard_full_backward',
        devices: _goldenDevices,
        customPump: _pumpOnce,
      );
    });

    testGoldens('Dashboard: нейтраль + кнопки швартовки (MooringMenu)', (tester) async {
      final game = YachtMasterGame();
      game.prepareStart(
        GameLevels.allLevels.first,
        windMult: 1.0,
        currentSpeed: 0,
        currentDirectionRad: 0,
        propellerRightHanded: true,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'monospace', primarySwatch: Colors.brown),
          home: GameView(game: game),
        ),
      );
      await tester.runAsync(() => game.ready());
      await tester.pump();

      game.yacht.velocity = Vector2.zero();
      game.yacht.targetThrottle = 0.0;
      game.showMooringButtons(true, true);
      await tester.pump();

      await multiScreenGolden(
        tester,
        'dashboard_neutral_mooring',
        devices: _goldenDevices,
        customPump: _pumpOnce,
      );
    });
  });

  group('Golden: Full Scene', () {
    testGoldens('Full Scene: причал сверху, яхта в нижней трети, зум ~50м', (tester) async {
      final game = YachtMasterGame();
      final config = LevelConfig(
        id: 99,
        name: 'Golden',
        description: '',
        envType: EnvironmentType.marina,
        startPos: Vector2(200, 50),
        startAngle: -90,
        marinaLayout: [
          BoatPlacement(type: 'player_slot'),
        ],
        defaultWindSpeed: 0,
        defaultCurrentSpeed: 0,
      );
      game.prepareStart(config, windMult: 1.0, propellerRightHanded: true);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'monospace', primarySwatch: Colors.brown),
          home: GameView(game: game),
        ),
      );
      await tester.runAsync(() => game.ready());
      await tester.pump();
      for (int i = 0; i < 20; i++) game.update(0.016);
      await tester.pump();

      await multiScreenGolden(
        tester,
        'full_scene_50m',
        devices: _goldenDevices,
        customPump: _pumpOnce,
      );
    });
  });
}
