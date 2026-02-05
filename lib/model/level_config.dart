import 'package:flame/extensions.dart';

enum EnvironmentType { marina, river, openSea }

class BoatPlacement {
  final String type; // 'boat' или 'player_slot'
  final double width;
  final double length;
  final String? sprite;
  final bool isNoseRight;

  BoatPlacement({
    required this.type,
    this.width = 4.0,
    this.length = 12.0,
    this.sprite,
    this.isNoseRight = true,
  });
}

class LevelConfig {
  final int id;
  final String name;
  final String description;
  final EnvironmentType envType;
  final Vector2 startPos; // В метрах
  final double startAngle;
  final List<BoatPlacement> marinaLayout;
  final double defaultWindSpeed;
  final double defaultCurrentSpeed;
  final double currentDirection;

  LevelConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.envType,
    required this.startPos,
    this.startAngle = -90,
    this.marinaLayout = const [],
    this.targetSlotIndex = 0,
    this.defaultWindSpeed = 2.0,
    this.defaultCurrentSpeed = 0.0,
    this.currentDirection = 0.0,
  });

  final int targetSlotIndex;
}

class GameLevels {
  static final List<LevelConfig> allLevels = [
    // УРОВЕНЬ 1: ИСПОЛЬЗУЕМ ВАШ СПИСОК
    LevelConfig(
      id: 1,
      name: "Первый причал",
      description: "Тихая марина. Запаркуйте яхту в свободный слот между другими судами.",
      envType: EnvironmentType.marina,
      startPos: Vector2(200, 45),
      marinaLayout: [
        BoatPlacement(type: 'boat', width: 3.0, length: 8.0, sprite: 'yacht_small.png', isNoseRight: true),
        BoatPlacement(type: 'boat', width: 4.0, length: 12.0, sprite: 'yacht_medium.png', isNoseRight: false),
        BoatPlacement(type: 'boat', width: 5.0, length: 10.0, sprite: 'yacht_motor.png', isNoseRight: true),
        BoatPlacement(type: 'player_slot'), // Твой слот (индекс 3)
        BoatPlacement(type: 'boat', width: 4.0, length: 12.0, sprite: 'yacht_medium.png', isNoseRight: false),
        BoatPlacement(type: 'boat', width: 3.0, length: 9.0, sprite: 'yacht_small.png', isNoseRight: true),
        BoatPlacement(type: 'boat', width: 10.0, length: 22.0, sprite: 'yacht_large.png', isNoseRight: true),
      ],
    ),

    // УРОВЕНЬ 2: ПРИМЕР ДЛЯ РЕКИ
    LevelConfig(
      id: 2,
      name: "Течение Сены",
      description: "Сложная швартовка на реке с сильным боковым течением.",
      envType: EnvironmentType.river,
      startPos: Vector2(150, 80),
      defaultCurrentSpeed: 1.8,
      currentDirection: 3.14, // Течение сносит вниз
      marinaLayout: [
        BoatPlacement(type: 'boat', width: 4.0, length: 12.0, sprite: 'yacht_medium.png', isNoseRight: false),
        BoatPlacement(type: 'player_slot'),
        BoatPlacement(type: 'boat', width: 10.0, length: 22.0, sprite: 'yacht_large.png', isNoseRight: true),
      ],
    ),
  ];
}