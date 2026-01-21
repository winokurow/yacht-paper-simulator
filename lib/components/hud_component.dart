import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:yacht/game/yacht_game.dart';
import '../core/constants.dart';

class YachtHud extends PositionComponent with HasGameReference<YachtMasterGame> {
  late TextComponent throttleText;
  late TextComponent rudderText;
  late TextComponent speedText;
  late TextComponent cogText; // Course Over Ground
  late TextComponent statusText;
  @override
  Future<void> onLoad() async {
    // Стиль для HUD (четкий шрифт с подложкой для читаемости)
    final textRenderer = TextPaint(
      style: const TextStyle(
        color: Colors.yellowAccent,
        fontSize: 16,
        fontFamily: 'monospace',
        backgroundColor: Colors.black45,
      ),
    );

    throttleText = TextComponent(text: '', position: Vector2(20, 20), textRenderer: textRenderer);
    rudderText = TextComponent(text: '', position: Vector2(20, 45), textRenderer: textRenderer);
    speedText = TextComponent(text: '', position: Vector2(20, 70), textRenderer: textRenderer);
    cogText = TextComponent(text: '', position: Vector2(20, 95), textRenderer: textRenderer);
    statusText = TextComponent(text: '', position: Vector2(20, 120), textRenderer: textRenderer);
    addAll([throttleText, rudderText, speedText, cogText, statusText]);
  }

  @override
  void update(double dt) {
    super.update(dt);

    final yacht = game.yacht;

    // 1. Мощность двигателя
    String engineDir = yacht.throttle >= 0 ? "FWD" : "REV";
    throttleText.text = 'ENGINE: $engineDir ${(yacht.throttle * 100).abs().toStringAsFixed(0)}%';

    // 2. Положение руля
    double rudderDeg = yacht.rudderAngle * 35; // Допустим, макс угол 35 градусов
    String rudderSide = rudderDeg > 0 ? "STBD" : (rudderDeg < 0 ? "PORT" : "CTR");
    rudderText.text = 'RUDDER: ${rudderDeg.abs().toStringAsFixed(1)}° $rudderSide';

    // 3. Скорость относительно воды (STW - Speed Through Water)
    // Если скорость > 1.0 и мы близко к причалу (условно), красим текст в красный
    if (game.yacht.velocity.length > 1.0) {
      speedText.textRenderer = TextPaint(style: TextStyle(color: Colors.redAccent, fontSize: 18));
    } else {
      speedText.textRenderer = TextPaint(style: TextStyle(color: Colors.yellowAccent, fontSize: 16));
    }
    double stw = yacht.velocity.length;
    speedText.text = 'STW (Water): ${stw.toStringAsFixed(1)} m/s';

    // 4. Скорость относительно дна (SOG - Speed Over Ground)
    // Учитываем вектор течения
    Vector2 currentVec = Vector2(cos(Constants.currentDirection), sin(Constants.currentDirection)) * Constants.currentSpeed;
    Vector2 sogVector = yacht.velocity + currentVec;
    double sog = sogVector.length;

    // Курс относительно дна (COG) в градусах
    double cog = (sogVector.angleToSigned(Vector2(1, 0)) * -180 / 3.1415) % 360;

    cogText.text = 'SOG (Ground): ${sog.toStringAsFixed(1)} m/s | COG: ${cog.toStringAsFixed(0)}°';

    statusText.text = 'STATUS: ${game.statusMessage}';
  }


}