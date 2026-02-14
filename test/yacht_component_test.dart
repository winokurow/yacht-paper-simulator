import 'dart:math' as math;

import 'package:flame/camera.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/sprite.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yacht/components/dock_component.dart';
import 'package:yacht/components/moored_yacht.dart';
import 'package:yacht/components/yacht_player.dart';
import 'package:yacht/core/constants.dart';
import 'package:yacht/game/yacht_game.dart';

// --- Mock для YachtMasterGame (для верификации вызовов) ---
class MockYachtMasterGame extends Mock implements YachtMasterGame {}

/// Тестовая игра: делегирует в mock методы, которые проверяем; минимальный onLoad без Dashboard/startLevel.
class TestYachtGame extends YachtMasterGame {
  TestYachtGame(this._mock);

  final MockYachtMasterGame _mock;

  @override
  Future<void> onLoad() async {
    camera.viewport = FixedResolutionViewport(resolution: Vector2(1280, 720));
    camera.viewfinder.anchor = const Anchor(0.5, 0.65);
    yacht = YachtPlayer(startAngleDegrees: 0);
    world.add(yacht);
    // Не добавляем Dashboard и не вызываем startLevel
  }

  @override
  Future<Sprite> loadSprite(
    String path, {
    Vector2? srcSize,
    Vector2? srcPosition,
  }) =>
      _mock.loadSprite(path, srcSize: srcSize, srcPosition: srcPosition);

  @override
  void onGameOver(String reason) => _mock.onGameOver(reason);

  @override
  void showMooringButtons(bool bow, bool stern) => _mock.showMooringButtons(bow, stern);

  @override
  void hideMooringButtons() => _mock.hideMooringButtons();

  @override
  double get activeCurrentSpeed => _mock.activeCurrentSpeed;

  @override
  double get activeCurrentDirection => _mock.activeCurrentDirection;

  @override
  Dock? get dock => _mock.dock;
}

/// Создаёт фейковый спрайт для тестов (без загрузки ассетов).
Future<Sprite> createFakeSprite() async {
  final image = await generateImage(2, 2);
  return Sprite(image);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockYachtMasterGame mockGame;
  late Sprite fakeSprite;

  setUpAll(() async {
    fakeSprite = await createFakeSprite();
  });

  setUp(() {
    mockGame = MockYachtMasterGame();
    when(() => mockGame.loadSprite(any())).thenAnswer((_) async => fakeSprite);
    when(() => mockGame.activeCurrentSpeed).thenReturn(0.0);
    when(() => mockGame.activeCurrentDirection).thenReturn(0.0);
    // Чтобы _checkMooringConditions не падал на game.dock!: заглушка с пустыми тумбами
    when(() => mockGame.dock).thenReturn(Dock(
      bollardXPositions: [],
      position: Vector2.zero(),
      size: Vector2(100, 140),
    ));
  });

  group('YachtPlayer component tests', () {
    group('Жизненный цикл и инициализация', () {
      testWithGame<TestYachtGame>(
        'YachtPlayer загружает спрайт и добавляет PolygonHitbox при добавлении в игру',
        () => TestYachtGame(mockGame),
        (game) async {
          await game.ready();
          final yacht = game.yacht;

          expect(yacht.yachtSprite, isNotNull);
          final hitboxes = yacht.children.whereType<PolygonHitbox>().toList();
          expect(hitboxes.length, 1);
        },
      );
    });

    group('Логика коллизий (Collision Handling)', () {
      testWithGame<TestYachtGame>(
        'Фатальный удар носом: onCollisionStart с Dock при local X > size.x*0.3 и высокой скорости вызывает game.onGameOver',
        () => TestYachtGame(mockGame),
        (game) async {
          await game.ready();
          final yacht = game.yacht;

          final dock = Dock(
            bollardXPositions: [50.0],
            position: Vector2(100, 50),
            size: Vector2(200, 140),
          );
          game.world.add(dock);
          await game.ready();

          yacht.position = Vector2(150, 80);
          yacht.velocity = Vector2(2.0, 0); // выше maxSafeImpactSpeed (1.5)
          // Точка удара в носу: в локальных координатах x > size.x * 0.3
          final localNose = Vector2(yacht.size.x * 0.5, 0);
          final worldCollisionPoint = yacht.localToParent(localNose);

          yacht.onCollisionStart({worldCollisionPoint}, dock);

          verify(() => mockGame.onGameOver(any())).called(1);
        },
      );

      testWithGame<TestYachtGame>(
        'Мягкое касание: удар в борт на низкой скорости гасит velocity, onGameOver не вызывается',
        () => TestYachtGame(mockGame),
        (game) async {
          await game.ready();
          final yacht = game.yacht;

          final dock = Dock(
            bollardXPositions: [50.0],
            position: Vector2(100, 50),
            size: Vector2(200, 140),
          );
          game.world.add(dock);
          await game.ready();

          yacht.position = Vector2(150, 80);
          yacht.velocity = Vector2(0.8, 0); // ниже maxSafeImpactSpeed
          // Удар в борт: локально x <= size.x * 0.3 (корма/борт)
          final localSide = Vector2(yacht.size.x * 0.1, yacht.size.y * 0.5);
          final worldCollisionPoint = yacht.localToParent(localSide);

          final velocityBefore = yacht.velocity.length;

          yacht.onCollisionStart({worldCollisionPoint}, dock);

          verifyNever(() => mockGame.onGameOver(any()));
          expect(yacht.velocity.length, lessThan(velocityBefore));
        },
      );

      testWithGame<TestYachtGame>(
        'Разрешение проникновения: выталкивание вдоль нормали (препятствие слева → сдвиг вправо)',
        () => TestYachtGame(mockGame),
        (game) async {
          await game.ready();
          final yacht = game.yacht;

          // Препятствие (другая яхта) слева от игрока; центры по одной вертикали.
          final obstacleCenter = Vector2(80.0, 100.0);
          final moored = MooredYacht(
            position: obstacleCenter,
            spritePath: 'yacht_paper.png',
            lengthInMeters: 10,
            widthInMeters: 3,
          );
          game.world.add(moored);
          await game.ready();

          yacht.position = Vector2(95.0, 100.0); // игрок справа от препятствия, перекрытие
          yacht.velocity = Vector2(0.5, 0);
          final collisionPoint = Vector2(87.0, 100.0);

          yacht.onCollisionStart({collisionPoint}, moored);

          // Нормаль (obstacle → player) направлена вправо (+x), выталкивание вправо.
          expect(yacht.position.x, greaterThan(95.0),
              reason: 'Игрок выталкивается вправо от препятствия слева');
        },
      );

      testWithGame<TestYachtGame>(
        'Разрешение проникновения: препятствие справа → сдвиг влево',
        () => TestYachtGame(mockGame),
        (game) async {
          await game.ready();
          final yacht = game.yacht;

          final obstacleCenter = Vector2(120.0, 100.0);
          final moored = MooredYacht(
            position: obstacleCenter,
            spritePath: 'yacht_paper.png',
            lengthInMeters: 10,
            widthInMeters: 3,
          );
          game.world.add(moored);
          await game.ready();

          yacht.position = Vector2(105.0, 100.0);
          yacht.velocity = Vector2(-0.5, 0);
          final collisionPoint = Vector2(112.0, 100.0);

          yacht.onCollisionStart({collisionPoint}, moored);

          expect(yacht.position.x, lessThan(105.0),
              reason: 'Игрок выталкивается влево от препятствия справа');
        },
      );

      testWithGame<TestYachtGame>(
        'Отражение скорости: после удара скорость отражена вдоль нормали (restitution)',
        () => TestYachtGame(mockGame),
        (game) async {
          await game.ready();
          final yacht = game.yacht;

          // Препятствие слева; игрок летит влево (к препятствию).
          final obstacleCenter = Vector2(80.0, 100.0);
          final moored = MooredYacht(
            position: obstacleCenter,
            spritePath: 'yacht_paper.png',
            lengthInMeters: 10,
            widthInMeters: 3,
          );
          game.world.add(moored);
          await game.ready();

          yacht.position = Vector2(95.0, 100.0);
          yacht.velocity = Vector2(-1.0, 0); // летим влево (к препятствию слева)

          yacht.onCollisionStart({Vector2(87.0, 100.0)}, moored);

          // Нормаль от препятствия к игроку = (+1, 0). После отражения v_new ≈ +v_old * restitution (вправо).
          expect(yacht.velocity.x, greaterThan(0),
              reason: 'Скорость отражена от препятствия слева — движение вправо');
          expect(yacht.velocity.length, lessThanOrEqualTo(1.0 * 0.5),
              reason: 'Модуль скорости уменьшен коэффициентом восстановления');
        },
      );
    });

    group('Интеграция с интерфейсом (Mooring UI)', () {
      testWithGame<TestYachtGame>(
        'Дистанция до швартовки: яхта рядом с тумбой вызывает showMooringButtons(true, ...)',
        () => TestYachtGame(mockGame),
        (game) async {
          await game.ready();
          final yacht = game.yacht;

          final bollardX = 200.0;
          final dock = Dock(
            bollardXPositions: [bollardX],
            position: Vector2(0, 0),
            size: Vector2(400, 140),
          );
          when(() => mockGame.dock).thenReturn(dock);
          game.world.add(dock);
          await game.ready();

          // Позиция: нос/корма близко к тумбе (bollardY = 0 + 140 = 140)
          final bollardY = dock.position.y + dock.size.y;
          yacht.position = Vector2(dock.position.x + bollardX, bollardY + 2.0 * Constants.pixelRatio);
          yacht.velocity = Vector2.zero();

          game.update(0.016);

          verify(() => mockGame.showMooringButtons(any(), any())).called(greaterThanOrEqualTo(1));
        },
      );

      testWithGame<TestYachtGame>(
        'Скрытие кнопок: при увеличении дистанции вызывается hideMooringButtons',
        () => TestYachtGame(mockGame),
        (game) async {
          await game.ready();
          final yacht = game.yacht;

          final dock = Dock(
            bollardXPositions: [100.0],
            position: Vector2(0, 0),
            size: Vector2(200, 140),
          );
          when(() => mockGame.dock).thenReturn(dock);
          game.world.add(dock);
          await game.ready();

          // Далеко от причала
          yacht.position = Vector2(500, 800);
          yacht.velocity = Vector2.zero();

          game.update(0.016);

          verify(() => mockGame.hideMooringButtons()).called(greaterThanOrEqualTo(1));
        },
      );
    });

    group('Ввод и управление (Keyboard Handling)', () {
      testWithGame<TestYachtGame>(
        'Нажатие W и несколько update(dt) увеличивают throttle',
        () => TestYachtGame(mockGame),
        (game) async {
          await game.ready();
          final yacht = game.yacht;

          expect(yacht.throttle, 0.0);

          // Имитация нажатия W: прямой вызов управления (targetThrottle), затем update для лерпа throttle
          yacht.targetThrottle += 0.8 * 0.016;
          for (int i = 0; i < 60; i++) {
            game.update(0.016);
          }

          expect(yacht.throttle, greaterThan(0));
        },
      );
    });
  });
}
