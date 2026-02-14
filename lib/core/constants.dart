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
  static const double propWalkEffect = 4.5;
  /// Дистанция до причала (в пикселях), ниже которой при заднем ходе отключаем смещение винта, чтобы не заезжать на причал.
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
// Скорость выше 0.8 м/с (около 1.5 узлов) при боковом ударе считается аварией
  static const double maxSafeImpactSpeed = 1.5;

}