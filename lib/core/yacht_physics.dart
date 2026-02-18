import 'dart:math' as math;
import 'package:flame/extensions.dart';
import 'constants.dart';

/// Чистые функции расчёта сил и моментов для яхты (без состояния).
class YachtPhysics {
  YachtPhysics._();

  /// Сила ветра [Н]. Направление ветра в радианах (компас: 0=С), скорость в м/с.
  /// Формула: F_wind = A * v_wind² * k (давление на парусность).
  static Vector2 windForce(double windSpeed, double windDirectionRad) {
    if (windSpeed <= 0) return Vector2.zero();
    double pushAngle = windDirectionRad + math.pi / 2;
    Vector2 dir = Vector2(math.cos(pushAngle), math.sin(pushAngle));
    double magnitude = Constants.windageArea * windSpeed * windSpeed * Constants.windForceFactor;
    return dir * magnitude;
  }

  /// Сила тяги двигателя [Н]. throttle in [-1, 1], angle в радианах.
  /// F_thrust = throttle * F_max * forward_dir (направление носа).
  static Vector2 thrustForce(double throttle, double angle) {
    Vector2 forward = Vector2(math.cos(angle), math.sin(angle));
    return forward * (throttle * Constants.maxThrust);
  }

  /// Сопротивление воды [Н]: линейное (вязкость) + квадратичное (форма корпуса).
  /// F_drag = -(c_linear * v + c_quad * v²) * v̂ — при больших v доминирует v².
  static Vector2 dragForce(Vector2 velocity) {
    double speed = velocity.length;
    if (speed < Constants.minSpeedForDrag) return Vector2.zero();
    double dragMag = (speed * Constants.linearDragCoefficient) +
        (speed * speed * Constants.quadraticDragCoefficient);
    return velocity.normalized() * (-dragMag);
  }

  /// Боковое сопротивление (эффект киля) [Н].
  /// Гасит дрейф: F_lateral = -m * k_lat * v_lateral (v_lateral — компонента скорости перпендикулярно носу).
  static Vector2 lateralDrag(Vector2 forwardDir, Vector2 velocity) {
    Vector2 lateralDir = Vector2(-forwardDir.y, forwardDir.x);
    double lateralSpeed = velocity.dot(lateralDir);
    return lateralDir * (-lateralSpeed * Constants.yachtMass * Constants.lateralDragMultiplier);
  }

  /// Момент от руля [Н·м]. Радиус разворота растёт с скоростью: на ходу руль «тупее».
  /// effective_flow = total_flow / (1 + v/v_ref) — при v >> v_ref момент растёт медленнее скорости,
  /// поэтому угловая скорость не линейна по v и R = v/ω увеличивается на высокой скорости.
  static double rudderTorque(double rudderAngle, double speedMeters, double throttle) {
    double propWash = throttle.abs() * Constants.propWashFactor;
    double totalFlow = speedMeters + propWash;
    double vRef = Constants.rudderSpeedReferenceForTurnRadius;
    double effectiveFlow = totalFlow / (1.0 + speedMeters / vRef);
    return rudderAngle * effectiveFlow * Constants.rudderEffect * Constants.rudderTorqueFactor;
  }

  /// Момент от заброса винта (prop walk) [Н·м].
  /// Максимум на старте; затухает с набором скорости: (1 - speed/5) в [0.2, 1].
  static double propWalkTorque(double throttle, double speedMeters) {
    if (throttle.abs() < Constants.propWalkThrottleThreshold) return 0;
    double sideSign = (Constants.propType == PropellerType.rightHanded) ? -1.0 : 1.0;
    double walkIntensity = (throttle < 0) ? Constants.propWalkIntensityReverse : Constants.propWalkIntensityForward;
    double speedStabilization = (1.0 - (speedMeters / Constants.propWalkSpeedStabilizationMeters))
        .clamp(Constants.propWalkSpeedClampMin, Constants.propWalkSpeedClampMax);
    return sideSign * throttle.sign * Constants.propWalkEffect * walkIntensity * speedStabilization * Constants.propWalkTorqueFactor;
  }

  /// Ускорение от натяжения каната. strain = currentLength - restLength (пиксели).
  /// Натяжение: T = k_lin*strain + k_quad*strain²; ускорение a = T/m; при большом strain — сильное демпфирование.
  static (Vector2 acceleration, double velocityDamping) mooringTension(
    Vector2 ropeDirectionNormalized,
    double strainPixels,
    double restLengthPixels,
    double yachtMass,
    double dt,
  ) {
    if (strainPixels <= 0) return (Vector2.zero(), 1.0);
    double tension = _mooringTensionMagnitude(strainPixels);
    Vector2 accel = ropeDirectionNormalized * (tension / yachtMass) * dt * Constants.mooringAccelScale;
    double damping = Constants.mooringDampingLight;
    if (restLengthPixels > 0 && strainPixels > restLengthPixels * Constants.mooringStrainRatioForStrongDamping) {
      damping = Constants.mooringDampingStrong;
    }
    return (accel, damping);
  }

  /// Величина натяжения по деформации (пиксели), ограниченная [Constants.maxLineTensionPixels].
  static double _mooringTensionMagnitude(double strainPixels) {
    double tension = strainPixels * Constants.mooringTensionLinear +
        (strainPixels * strainPixels * Constants.mooringTensionQuadratic);
    return tension.clamp(0.0, Constants.maxLineTensionPixels);
  }

  /// Натяжение шпринга: только продольная компонента (вдоль [forwardDir]).
  /// Ограничивает движение вперёд/назад, позволяет яхте разворачиваться от причала.
  static (Vector2 acceleration, double velocityDamping) mooringSpringLongitudinal(
    Vector2 ropeDirectionNormalized,
    double strainPixels,
    double restLengthPixels,
    Vector2 forwardDir,
    double yachtMass,
    double dt,
  ) {
    if (strainPixels <= 0) return (Vector2.zero(), 1.0);
    double tension = _mooringTensionMagnitude(strainPixels) * Constants.mooringSpringElasticity;
    double longitudinalComponent = ropeDirectionNormalized.dot(forwardDir);
    Vector2 accelDir = forwardDir * longitudinalComponent.sign;
    Vector2 accel = accelDir * (tension / yachtMass) * dt * Constants.mooringAccelScale;
    double damping = Constants.mooringDampingLight;
    if (restLengthPixels > 0 && strainPixels > restLengthPixels * Constants.mooringStrainRatioForStrongDamping) {
      damping = Constants.mooringDampingStrong;
    }
    return (accel, damping);
  }

  /// Мгновенная остановка: обнуляет линейную и угловую скорости (вызывать из onCollision при ударе).
  static void stop(void Function(Vector2 linearVelocity, double angularVelocity) setVelocities) {
    setVelocities(Vector2.zero(), 0);
  }

  /// Количество шагов субстеппинга и dt одного шага. distPixels — перемещение за кадр в пикселях.
  static (int steps, double stepDt) integrationSteps(double distPixels, double dt, {int? maxSteps, double? stepSize}) {
    final max = maxSteps ?? Constants.integrationMaxSteps;
    final size = stepSize ?? Constants.integrationStepSizePixels;
    if (distPixels <= Constants.integrationDistThreshold) return (0, 0);
    int steps = (distPixels / size).ceil().clamp(1, max);
    return (steps, dt / steps);
  }
}

/// Состояние движения яхты для пошаговой симуляции.
/// [effectiveThrust] — сглаженная тяга (инерция двигателя), используется для расчёта силы тяги.
class YachtMotionState {
  Vector2 position;
  double angle;
  Vector2 velocity;
  double angularVelocity;
  double throttle;
  double effectiveThrust;
  double currentRudderAngle;

  YachtMotionState({
    required this.position,
    required this.angle,
    required this.velocity,
    required this.angularVelocity,
    required this.throttle,
    required this.effectiveThrust,
    required this.currentRudderAngle,
  });

  YachtMotionState copyWith({
    Vector2? position,
    double? angle,
    Vector2? velocity,
    double? angularVelocity,
    double? throttle,
    double? effectiveThrust,
    double? currentRudderAngle,
  }) {
    return YachtMotionState(
      position: position ?? this.position,
      angle: angle ?? this.angle,
      velocity: velocity ?? this.velocity,
      angularVelocity: angularVelocity ?? this.angularVelocity,
      throttle: throttle ?? this.throttle,
      effectiveThrust: effectiveThrust ?? this.effectiveThrust,
      currentRudderAngle: currentRudderAngle ?? this.currentRudderAngle,
    );
  }
}

/// Параметры окружения для шага симуляции.
class YachtEnvironment {
  final double windSpeed;
  final double windDirection;
  final double currentSpeed;
  final double currentDirection;
  final double distanceToDockPixels;
  final bool isTouchingDock;

  const YachtEnvironment({
    this.windSpeed = 0,
    this.windDirection = 0,
    this.currentSpeed = 0,
    this.currentDirection = 0,
    this.distanceToDockPixels = double.infinity,
    this.isTouchingDock = false,
  });
}

/// Вычисление движения яхты: инерция, сопротивление, руль, интеграция.
/// Все расчёты движения и сопротивления воды сосредоточены здесь.
class YachtDynamics {
  final double pixelRatio;

  YachtDynamics({double? pixelRatio}) : pixelRatio = pixelRatio ?? Constants.pixelRatio;

  /// Один шаг симуляции. Возвращает новое состояние.
  /// [targetThrottle], [targetRudderAngle] — целевые значения управления.
  YachtMotionState step(
    YachtMotionState state,
    double targetThrottle,
    double targetRudderAngle,
    YachtEnvironment env,
    double dt,
  ) {
    if (dt > 0.1) return state;

    // 1. Течение
    Vector2 position = state.position;
    if (env.currentSpeed > 0) {
      Vector2 currentFlow = Vector2(
        math.cos(env.currentDirection),
        math.sin(env.currentDirection),
      ) * env.currentSpeed;
      position += currentFlow * (dt * pixelRatio);
    }

    // 2. Сглаживание газа (целевое значение для отображения и prop walk)
    double throttle = state.throttle;
    if ((throttle - targetThrottle).abs() > Constants.throttleSmoothDeadZone) {
      throttle += (targetThrottle > throttle ? 1 : -1) * Constants.throttleChangeSpeed * dt;
      throttle = throttle.clamp(-1.0, 1.0);
    }

    // 3. Инерция двигателя: эффективная тяга догоняет газ (даёт плавный разгон/торможение)
    double effectiveThrust = state.effectiveThrust;
    effectiveThrust += (throttle - effectiveThrust) * Constants.thrustResponseRate * dt;
    effectiveThrust = effectiveThrust.clamp(-1.0, 1.0);

    // 4. Сглаживание руля (физическое перо поворачивается с ограниченной скоростью)
    double rudderAngle = state.currentRudderAngle;
    double rudderDiff = targetRudderAngle - rudderAngle;
    double rudderStep = Constants.rudderRotationSpeed * dt;
    if (rudderDiff.abs() <= rudderStep) {
      rudderAngle = targetRudderAngle;
    } else if (rudderDiff.abs() > Constants.rudderStepThreshold) {
      rudderAngle += rudderDiff.sign * rudderStep;
    }

    // 5. Силы и линейное ускорение: a = F/m, v_new = v + a*dt (импульс/инерция через массу)
    double speedMeters = state.velocity.length;
    Vector2 forwardDir = Vector2(math.cos(state.angle), math.sin(state.angle));
    Vector2 thrust = YachtPhysics.thrustForce(effectiveThrust, state.angle);
    Vector2 wind = YachtPhysics.windForce(env.windSpeed, env.windDirection);
    Vector2 drag = YachtPhysics.dragForce(state.velocity);
    Vector2 lateral = YachtPhysics.lateralDrag(forwardDir, state.velocity);
    Vector2 totalForce = thrust + wind + drag + lateral;
    Vector2 velocity = state.velocity + (totalForce / Constants.yachtMass) * dt;
    if (velocity.length > Constants.maxSpeedMeters) {
      velocity = velocity.normalized() * Constants.maxSpeedMeters;
    }

    // 6. Вращение: момент руля (с учётом радиуса разворота) + prop walk; угловое трение
    double propWalk = YachtPhysics.propWalkTorque(throttle, speedMeters);
    if (env.isTouchingDock ||
        (throttle < 0 && env.distanceToDockPixels < Constants.propWalkSuppressDistanceToDockPixels)) {
      propWalk = 0;
    }
    double totalTorque = YachtPhysics.rudderTorque(rudderAngle, speedMeters, throttle) + propWalk;
    double angularVelocity = state.angularVelocity + (totalTorque / Constants.yachtInertia) * dt;
    angularVelocity *= (1.0 - (Constants.angularDrag * dt)).clamp(0.0, 1.0);
    angularVelocity = angularVelocity.clamp(-Constants.maxAngularVelocity, Constants.maxAngularVelocity);

    // 7. Интеграция (субстеппинг): x_new = x + v*dt, θ_new = θ + ω*dt (м/с → пиксели через pixelRatio)
    double distThisFrame = velocity.length * dt * pixelRatio;
    var (steps, stepDt) = YachtPhysics.integrationSteps(distThisFrame, dt);
    double angle = state.angle;
    for (int i = 0; i < steps; i++) {
      position += velocity * (stepDt * pixelRatio);
      angle += angularVelocity * stepDt;
    }

    // 8. Стабилизация (анти-дрожание при почти нулевой скорости)
    if (throttle.abs() < Constants.throttleZeroThreshold && velocity.length < Constants.velocityZeroThreshold) {
      velocity = Vector2.zero();
      if (angularVelocity.abs() < Constants.angularZeroThreshold) angularVelocity = 0;
    }

    return YachtMotionState(
      position: position,
      angle: angle,
      velocity: velocity,
      angularVelocity: angularVelocity,
      throttle: throttle,
      effectiveThrust: effectiveThrust,
      currentRudderAngle: rudderAngle,
    );
  }
}
