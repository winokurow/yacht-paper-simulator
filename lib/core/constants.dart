enum PropellerType { leftHanded, rightHanded }

class Constants {
  // 1 метр = 10 пикселей. Это значит, что лодка длиной 12м = 120 пикселей.
  static const double pixelRatio = 25.0;

  // --- ФИЗИКА (Приведенная к реальности) ---
  // Для 5-тонной яхты (5000 кг)
  static const double yachtMass = 2500.0;
  // Тяга двигателя (для яхты 50л.с. это примерно 3000-5000 Ньютонов)
  static const double maxThrust = 5000.0;

  static const double dragCoefficient = 150.0;   // Сопротивление воды
  static const double angularDrag = 5;
  static const double rudderEffect = 1.5;       // Эффективность руля

  // Скорость: 6 м/с — это примерно 11-12 узлов (очень быстро для яхты)
  static const double maxSpeedMeters = 3.0;

  static const double minSpeedThreshold = 0.01;
  static const double rudderRotationSpeed = 3;
  static const double propWashFactor = 1.2;

// Линейное сопротивление (вязкость) - работает на малых скоростях
  static const double linearDragCoefficient = 300.0;
  // Квадратичное сопротивление (форма корпуса) - работает на высоких скоростях
  static const double quadraticDragCoefficient = 400.0;

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
}