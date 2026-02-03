enum PropellerType { leftHanded, rightHanded }

class Constants {
  // 1 метр = 10 пикселей. Это значит, что лодка длиной 12м = 120 пикселей.
  static const double pixelRatio = 10.0;

  // --- ФИЗИКА (Приведенная к реальности) ---
  // Для 5-тонной яхты (5000 кг)
  static const double yachtMass = 4000.0;
  // Тяга двигателя (для яхты 50л.с. это примерно 3000-5000 Ньютонов)
  static const double maxThrust = 4000.0;

  static const double dragCoefficient = 500.0;   // Сопротивление воды
  static const double angularDrag = 5;
  static const double rudderEffect = 1.5;       // Эффективность руля

  // Скорость: 6 м/с — это примерно 11-12 узлов (очень быстро для яхты)
  static const double maxSpeed = 6.0 * Constants.pixelRatio;

  static const double minSpeedThreshold = 0.01;
  static const double rudderRotationSpeed = 3;
  static const double propWashFactor = 1.2;

  static const double lateralDragMultiplier = 2000.0; // Сопротивление боковому дрейфу
  static PropellerType propType = PropellerType.rightHanded;
  static const double propWalkEffect = 3;
  static const double yachtInertia = 3000.0;

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
  static const double damageThreshold = 1.5; // Порог повреждений в м/с
}