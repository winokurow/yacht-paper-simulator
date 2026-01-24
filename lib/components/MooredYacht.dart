import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/yacht_game.dart';
import '../core/constants.dart';

class MooredYacht extends SpriteComponent
    with HasGameReference<YachtMasterGame>, CollisionCallbacks {
  final String spritePath;
  final String hitboxType;
  final bool isNoseRight;

  MooredYacht({
    required Vector2 position,
    required this.spritePath,
    required double lengthInMeters,
    required double widthInMeters,
    this.hitboxType = 'pointy', // По умолчанию острый
    this.isNoseRight = true,    // По умолчанию вправо
  }) : super(
    position: position..round(),
    size: Vector2(
      (lengthInMeters * Constants.pixelRatio).roundToDouble(),
      (widthInMeters * Constants.pixelRatio).roundToDouble(),
    ),
    anchor: Anchor.center,
    priority: 5,
  );

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite(spritePath);


    // ВЫБОР ХИТБОКСА
    if (hitboxType == 'square') {
      // Для прямоугольных судов (баржи, понтоны)
      add(RectangleHitbox()..collisionType = CollisionType.passive);
    } else {
      // Для остроносых яхт
      _addPointyHitbox();
    }
  }

  void _addPointyHitbox() {
    final w = size.x;
    final h = size.y;
    List<Vector2> shape;

    if (isNoseRight) {
      // Нос справа (стандарт)
      shape = [
        Vector2(w, h * 0.5),     // Нос
        Vector2(w * 0.8, 0),     // Верхнее плечо
        Vector2(0, 0),           // Верхняя корма
        Vector2(0, h),           // Нижняя корма
        Vector2(w * 0.8, h),     // Нижнее плечо
      ];
    } else {
      // Нос слева (зеркально по горизонтали)
      shape = [
        Vector2(0, h * 0.5),     // Нос теперь слева (x=0)
        Vector2(w * 0.2, 0),     // Верхнее плечо (отступ от левого края)
        Vector2(w, 0),           // Верхняя корма теперь справа (x=w)
        Vector2(w, h),           // Нижняя корма теперь справа (x=w)
        Vector2(w * 0.2, h),     // Нижнее плечо
      ];
    }

    add(PolygonHitbox(shape)..collisionType = CollisionType.passive);
  }
}