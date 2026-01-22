enum PropellerType { leftHanded, rightHanded }

class Constants {
  static const double pixelRatio = 10.0; // 1 метр = 10 пикселей

// --- НАСТРОЙКИ "СПОРТ-РЕЖИМ" ---

  // Параметры для US 1.1
  static const double yachtMass = 5000.0;       // 5 тонн
  static const double dragCoefficient = 300.0; // Сопротивление воды
  static const double maxThrust = 15000.0;     // Мощность двигателя в Ньютонах
  static const double minSpeedThreshold = 0.05; // Скорость, ниже которой считаем остановку
  static const double angularDrag = 50.0;    // Сопротивление вращению
  static const double rudderEffect = 1.6;     // Насколько эффективно руль поворачивает лодку


  // Сопротивление дрейфу (боковое)
  static const double lateralDragMultiplier = 10.0;

  // Конфигурация винта
  static const PropellerType propType = PropellerType.rightHanded;

  // Сила эффекта (подбирается экспериментально)
  // На реверсе эффект обычно в 2-3 раза сильнее, чем на переднем ходу
  static const double propWalkFactor = 0.05;

  // Параметры ветра
  static const double windSpeed = 50.0; // Скорость ветра (м/с), примерно 20 узлов
  static const double windDirection = 0.0; // Направление ветра в радианах (0 = справа направо)
  static const double windageArea = 15.0; // Площадь парусности корпуса (условно)

// Параметры течения (Current)
  static const double currentSpeed = 0.0; // Скорость течения (м/с, около 1 узла)
  static const double currentDirection = 1.57; // Направление (в радианах, 1.57 рад ≈ 90° - строго вниз)

  static const double restitution = 0.4; // 0.0 - липнет, 1.0 - идеальный отскок как мячик
  static const double damageThreshold = 1.0; // Скорость, выше которой лодка ломается

}