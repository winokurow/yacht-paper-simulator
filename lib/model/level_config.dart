import 'package:flame/extensions.dart';

// 1. Типы локаций
enum EnvironmentType { marina, river, openSea }

// 2. Описание того, что стоит у причала
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

// 3. Основной конфиг уровня
class LevelConfig {
  final int id;
  final String name;
  final String description;
  final EnvironmentType envType;

// Позиция игрока
  final Vector2 startPos;
  final double startAngle;

// Окружение
  final List<BoatPlacement> marinaLayout;
  final int targetSlotIndex;

// Физика (по умолчанию)
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
}

// 4. Твоя база уровней
class GameLevels {
  static final List<LevelConfig> allLevels = [
    LevelConfig(
      id: 1,
      name: "Первый причал",
      description: "Тихая марина. Место для парковки отмечено зеленым.",
      envType: EnvironmentType.marina,
      startPos: Vector2(1000, 600),
      marinaLayout: [
        BoatPlacement(type: 'boat', width: 3, length: 8, sprite: 'yacht_small.png'),
        BoatPlacement(type: 'player_slot'),
        BoatPlacement(type: 'boat', width: 4, length: 12, sprite: 'yacht_medium.png'),
      ],
    ),
    LevelConfig(
      id: 2,
      name: "Течение Сены",
      description: "В реке лодку постоянно сносит течением. Будьте осторожны!",
      envType: EnvironmentType.river,
      startPos: Vector2(1000, 800),
      defaultCurrentSpeed: 1.5,
      currentDirection: 3.14, // Направление вниз
      marinaLayout: [
        BoatPlacement(type: 'boat', width: 4, length: 12, sprite: 'yacht_medium.png'),
        BoatPlacement(type: 'player_slot'),
      ],
    ),
  ];
}