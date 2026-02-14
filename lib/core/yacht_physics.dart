import 'dart:math' as math;
import 'package:flame/extensions.dart';
import 'constants.dart';

/// Чистые функции расчёта сил и моментов для яхты (без состояния).
class YachtPhysics {
  YachtPhysics._();

  /// Сила ветра [Н]. Направление ветра в радианах (компас: 0=С), скорость в м/с.
  static Vector2 windForce(double windSpeed, double windDirectionRad) {
    if (windSpeed <= 0) return Vector2.zero();
    double pushAngle = windDirectionRad + math.pi / 2;
    Vector2 dir = Vector2(math.cos(pushAngle), math.sin(pushAngle));
    double magnitude = Constants.windageArea * windSpeed * windSpeed * 20.0;
    return dir * magnitude;
  }

  /// Сила тяги двигателя [Н]. throttle in [-1, 1], angle в радианах.
  static Vector2 thrustForce(double throttle, double angle) {
    Vector2 forward = Vector2(math.cos(angle), math.sin(angle));
    return forward * (throttle * Constants.maxThrust);
  }

  /// Гибридное сопротивление воды [Н]: линейное + квадратичное.
  static Vector2 dragForce(Vector2 velocity) {
    double speed = velocity.length;
    if (speed < 0.001) return Vector2.zero();
    double dragMag = (speed * Constants.linearDragCoefficient) +
        (speed * speed * Constants.quadraticDragCoefficient);
    return velocity.normalized() * (-dragMag);
  }

  /// Боковое сопротивление (эффект киля) [Н].
  static Vector2 lateralDrag(Vector2 forwardDir, Vector2 velocity) {
    Vector2 lateralDir = Vector2(-forwardDir.y, forwardDir.x);
    double lateralSpeed = velocity.dot(lateralDir);
    return lateralDir * (-lateralSpeed * Constants.yachtMass * Constants.lateralDragMultiplier);
  }

  /// Момент от руля [Н·м]. rudderAngle, speedMeters, throttle — текущие значения.
  static double rudderTorque(double rudderAngle, double speedMeters, double throttle) {
    double propWash = throttle.abs() * Constants.propWashFactor;
    double totalFlow = speedMeters + propWash;
    return rudderAngle * totalFlow * Constants.rudderEffect * 800;
  }

  /// Момент от заброса винта (prop walk) [Н·м].
  /// Максимум на старте, плавно затухает с набором скорости (стабилизация руля в потоке).
  static double propWalkTorque(double throttle, double speedMeters) {
    if (throttle.abs() < 0.05) return 0;
    double sideSign = (Constants.propType == PropellerType.rightHanded) ? -1.0 : 1.0;
    double walkIntensity = (throttle < 0) ? 1.0 : 0.15;
    double speedStabilization = (1.0 - (speedMeters / 5.0)).clamp(0.2, 1.0);
    return sideSign * throttle.sign * Constants.propWalkEffect * walkIntensity * speedStabilization * 2000;
  }

  /// Ускорение от натяжения каната [м/с²]. strain = currentLength - restLength (в пикселях).
  /// Возвращает (acceleration vector, velocityDamping 0..1).
  static (Vector2 acceleration, double velocityDamping) mooringTension(
    Vector2 ropeDirectionNormalized,
    double strainPixels,
    double restLengthPixels,
    double yachtMass,
    double dt,
  ) {
    if (strainPixels <= 0) return (Vector2.zero(), 1.0);
    double tension = strainPixels * 45.0 + (strainPixels * strainPixels * 0.2);
    Vector2 accel = ropeDirectionNormalized * (tension / yachtMass) * dt * 160;
    double damping = 0.97;
    if (restLengthPixels > 0 && strainPixels > restLengthPixels * 0.2) damping = 0.92;
    return (accel, damping);
  }

  /// Мгновенная остановка: обнуляет линейную и угловую скорости (вызывать из onCollision при ударе).
  static void stop(void Function(Vector2 linearVelocity, double angularVelocity) setVelocities) {
    setVelocities(Vector2.zero(), 0);
  }

  /// Количество шагов субстеппинга и dt одного шага. distPixels — перемещение за кадр в пикселях.
  static (int steps, double stepDt) integrationSteps(double distPixels, double dt, {int maxSteps = 25, double stepSize = 1.0}) {
    if (distPixels <= 0.001) return (0, 0);
    int steps = (distPixels / stepSize).ceil().clamp(1, maxSteps);
    return (steps, dt / steps);
  }
}
