enum PropellerType { leftHanded, rightHanded }

class Constants {
  // 1 метр = 10 пикселей. Это значит, что лодка длиной 12м = 120 пикселей.
  static const double pixelRatio = 25.0;

  // --- ФИЗИКА (Приведенная к реальности) ---
  // Для 5-тонной яхты (5000 кг)
  static const double yachtMass = 2500.0;
  // Тяга двигателя (для яхты 50л.с. это примерно 3000-5000 Ньютонов)
  static const double maxThrust = 7000.0;

  static const double dragCoefficient = 150.0;   // Сопротивление воды
  static const double angularDrag = 5;
  static const double rudderEffect = 1.5;       // Эффективность руля

  // Скорость: 6 м/с — это примерно 11-12 узлов (очень быстро для яхты)
  static const double maxSpeedMeters = 3.0;

  static const double minSpeedThreshold = 0.01;
  static const double rudderRotationSpeed = 3;
  static const double propWashFactor = 1.2;

  /// Линейное сопротивление (вязкость) — на малых скоростях.
  static const double linearDragCoefficient = 150.0;
  /// Квадратичное сопротивление (форма корпуса) — растёт как v², доминирует на ходу.
  static const double quadraticDragCoefficient = 900.0;
  /// Скорость отклика тяги (1/с): эффективная тяга догоняет газ — даёт ощущение инерции двигателя.
  static const double thrustResponseRate = 2.0;
  /// Опорная скорость (м/с): выше неё эффективность руля снижается — растёт радиус разворота.
  static const double rudderSpeedReferenceForTurnRadius = 1.2;

  static const double lateralDragMultiplier = 5.0; // Эффект киля
  static PropellerType propType = PropellerType.rightHanded;
  /// Эффект заброса кормы (prop walk); снижен под массу яхты, чтобы не заезжать на причал.
  static const double propWalkEffect = 3.2;
  /// Дистанция до причала (пиксели), ниже которой при заднем ходе отключаем prop walk.
  static const double propWalkSuppressDistanceToDockPixels = 4.0 * pixelRatio;
  static const double yachtInertia = 6000.0;

  static const double mooringSpringStiffness = 150.0; // Жесткость каната
  static const double mooringDamping = 40.0;         // Гашение колебаний
  static const double maxMooringForce = 2000.0;       // Ограничитель силы рывка
  static const double maxRopeLength = 2.0;            // Длина каната в метрах
  static const double maxRopeExtension = 5.0;

  // --- ОКРУЖАЮЩАЯ СРЕДА ---
  static const double windSpeed = 0.0;      // 5 м/с — приятный бриз
  static const double windDirection = 0.0;
  static const double windageArea = 10.0;

  static const double currentSpeed = 0.0;   // 0.2 м/с — слабое течение
  static const double currentDirection = 1.57;

  static const double restitution = 0.3;    // Мягкий отскок
  /// Скорость выше порога при боковом ударе считается аварией (м/с).
  static const double maxSafeImpactSpeed = 1.5;

  // --- ВВОД (скорость изменения от клавиш за 1 с) ---
  static const double inputThrottleRate = 0.8;
  static const double inputRudderRate = 1.2;

  // --- ПОБЕДА И ШВАРТОВКА ---
  /// Порог скорости (пиксели/кадр), ниже которого яхта считается остановленной для победы.
  static const double victorySpeedThresholdPixels = 0.2 * pixelRatio;
  /// Скорость изменения газа к targetThrottle за 1 с.
  static const double throttleChangeSpeed = 1.2;
  /// Порог линейной скорости для обнуления (анти-дрожание).
  static const double velocityZeroThreshold = 0.05;
  /// Порог угловой скорости для обнуления.
  static const double angularZeroThreshold = 0.005;
  /// Сектор носа: локальный X > size.x * noseSectorFactor считается ударом носом.
  static const double noseSectorFactor = 0.3;
  /// Дистанция до тумбы (пиксели), в пределах которой доступна швартовка.
  static const double mooringBollardProximityPixels = 3.5 * pixelRatio;
  /// Макс. скорость (пиксели/кадр) для показа кнопок швартовки.
  static const double mooringSpeedThresholdPixels = 1.2 * pixelRatio;

  // --- МИР ---
  static const double playAreaWidth = 10000.0;
  static const double playAreaHeight = 10000.0;
  /// Смещение фона "стола" под бумагой.
  static const double tableOffsetX = -4000.0;
  static const double tableOffsetY = -3000.0;
  static const double tableSize = 10000.0;
  /// Высота причала (пиксели).
  static const double dockHeightPixels = 140.0;

  // --- ФИЗИКА: дополнительные коэффициенты (из yacht_physics) ---
  /// Множитель силы ветра (площадь × коэффициент).
  static const double windForceFactor = 28.0;
  /// Порог скорости (м/с), ниже которого сопротивление не считается.
  static const double minSpeedForDrag = 0.001;
  /// Порог газа, ниже которого prop walk не действует.
  static const double propWalkThrottleThreshold = 0.05;
  /// Интенсивность prop walk при заднем ходе (1.0) и переднем (0.15).
  static const double propWalkIntensityReverse = 1.0;
  static const double propWalkIntensityForward = 0.15;
  /// Скорость (м/с), при которой prop walk полностью стабилизируется.
  static const double propWalkSpeedStabilizationMeters = 5.0;
  /// Ограничение затухания prop walk от скорости [0.2, 1.0].
  static const double propWalkSpeedClampMin = 0.2;
  static const double propWalkSpeedClampMax = 1.0;
  /// Множитель момента руля (Н·м на единицу потока).
  static const double rudderTorqueFactor = 800.0;
  /// Множитель момента prop walk.
  static const double propWalkTorqueFactor = 2000.0;
  /// Жёсткость каната (линейная часть натяжения).
  static const double mooringTensionLinear = 45.0;
  /// Жёсткость каната (квадратичная часть).
  static const double mooringTensionQuadratic = 0.2;
  /// Масштаб ускорения от каната (интеграция).
  static const double mooringAccelScale = 160.0;
  /// Демпфирование скорости при натяжении каната (слабое).
  static const double mooringDampingLight = 0.97;
  /// Демпфирование при сильном натяжении (>20% от длины).
  static const double mooringDampingStrong = 0.92;
  /// Доля длины каната, выше которой включается сильное демпфирование.
  static const double mooringStrainRatioForStrongDamping = 0.2;
  /// Макс. шагов субстеппинга интеграции.
  static const int integrationMaxSteps = 25;
  /// Размер шага (пиксели) для субстеппинга.
  static const double integrationStepSizePixels = 1.0;
  /// Порог перемещения (пиксели), ниже которого субстеппинг не делаем.
  static const double integrationDistThreshold = 0.001;

  // --- КОЛЛИЗИИ И ОТРИСОВКА (yacht_player) ---
  /// Коэффициент восстановления при отражении скорости (мягкий отскок).
  static const double collisionRestitution = 0.35;
  /// Затухание угловой скорости при мягком столкновении.
  static const double collisionAngularDamping = 0.3;
  /// Порог нормали для совпадения центров.
  static const double collisionZeroNormalThreshold = 1e-6;
  /// Доля меньшей стороны для приближённого радиуса.
  static const double collisionApproximateRadiusFactor = 0.5;
  /// Смещение точки крепления швартовых от борта (доля ширины).
  static const double ropeOffsetFromBoard = 0.12;
  /// Позиция носового крепления (доля длины от носа: 0.2 = 20% от носа).
  static const double ropeBowPositionFactor = 0.20;
  /// Позиция кормового крепления (0.98 от носа).
  static const double ropeSternPositionFactor = 0.98;
  /// Порог разницы throttle для сглаживания.
  static const double throttleSmoothDeadZone = 0.01;
  /// Порог разницы руля для шага.
  static const double rudderStepThreshold = 0.001;
  /// Макс. угловая скорость (рад/с).
  static const double maxAngularVelocity = 1.2;
  /// Минимальный газ для обнуления скорости (стабилизация).
  static const double throttleZeroThreshold = 0.01;
  /// Минимальный интервал между всплесками (с).
  static const double splashCooldownSeconds = 0.4;
  /// Длина пера руля для отрисовки (доля длины яхты).
  static const double rudderDrawLengthFactor = 0.18;
  /// Порог дистанции (× pixelRatio) для провисания каната при отрисовке.
  static const double ropeSagDistanceFactor = 3.0;
  /// Коэффициент провисания дуги каната.
  static const double ropeSagFactor = 0.4;
}