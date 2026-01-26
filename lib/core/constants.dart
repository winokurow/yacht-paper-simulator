enum PropellerType { leftHanded, rightHanded }

class Constants {
  static const double pixelRatio = 10.0; // 1 метр = 10 пикселей

  // Параметры для US 1.1
  static const double yachtMass = 1000.0;       // 5 тонн
  static const double maxThrust = 15000.0;     // Мощность двигателя в Ньютонах
  static const double minSpeedThreshold = 0.05; // Скорость, ниже которой считаем остановку
  static const double angularDrag = 50.0;    // Сопротивление вращению
  static const double rudderEffect = 1.6;     // Насколько эффективно руль поворачивает лодку
  static const double maxSpeed = 6.0 * Constants.pixelRatio; // Абсолютный предел
  static const double dragCoefficient = 0.25; // Насколько "вязкая" вода
// СКОРОСТЬ ПОВОРОТА РУЛЯ
  // 2.0 означает, что от края до края руль переложится примерно за 1 секунду.
  // Чем меньше число, тем "тяжелее" ощущается штурвал.
  static const double rudderRotationSpeed = 2.0;
  static const double propWashFactor = 2.0; // Насколько сильно винт обдувает руль

  // Сопротивление дрейфу (боковое)
  static const double lateralDragMultiplier = 10.0;

  // Конфигурация винта
  static const PropellerType propType = PropellerType.rightHanded;

  // Сила эффекта (подбирается экспериментально)
  // На реверсе эффект обычно в 2-3 раза сильнее, чем на переднем ходу
  static const double propWalkEffect = 5;

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