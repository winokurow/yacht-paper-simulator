enum PropellerType { leftHanded, rightHanded }

class Constants {
  // 1 метр = 10 пикселей. Это значит, что лодка длиной 12м = 120 пикселей.
  static const double pixelRatio = 25.0;

  // --- ОТРИСОВКА (Flame priority: больше — выше слой) ---
  /// Сваи Baltic: ниже яхты игрока, чтобы корпус не «уезжал под» столбы в плане.
  static const int renderPriorityPile = 1;
  /// Яхта игрока: выше свай и маркеров причала, ниже канатов и чужих яхт.
  static const int renderPriorityPlayerYacht = 2;

  // --- ФИЗИКА (Приведенная к реальности) ---
  // Для 5-тонной яхты (5000 кг)
  static const double yachtMass = 2500.0;
  /// Тяга двигателя [Н]. Подобрано так, чтобы при среднем ветре (~5 м/с) лодка могла идти против ветра на 70–100% газа.
  static const double maxThrust = 9000.0;

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
  static const double propWalkEffect = 1.3;
  /// Дистанция до причала (пиксели), ниже которой при заднем ходе отключаем prop walk.
  static const double propWalkSuppressDistanceToDockPixels = 4.0 * pixelRatio;
  /// Момент инерции (кг·м²). Меньше — быстрее отклик руля и меньше радиус разворота.
  static const double yachtInertia = 5000.0;

  static const double mooringSpringStiffness = 150.0; // Жесткость каната
  static const double mooringDamping = 40.0;         // Гашение колебаний
  static const double maxMooringForce = 2000.0;       // Ограничитель силы рывка
  static const double maxLineTensionPixels = 800.0;    // Макс. натяжение (пиксели) для ограничения силы
  static const double mooringSpringElasticity = 0.4;  // Упругость шпрингов (доля от полного натяжения)
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
  /// Дистанция до якоря муринга (пиксели). Чуть больше, чем до тумбы, чтобы кнопка срабатывала уверенно.
  static const double mooringAnchorProximityPixels = 5.0 * pixelRatio;
  /// Дистанция до сваи (пиксели), в пределах которой доступна швартовка на Baltic (уровень 5).
  static const double pileMooringProximityPixels = 8.0 * pixelRatio;
  /// Макс. скорость (пиксели/кадр) для показа кнопок швартовки.
  static const double mooringSpeedThresholdPixels = 1.2 * pixelRatio;
  /// Радиус отображаемой точки якоря муринга (пиксели).
  static const double mooringAnchorMarkerRadiusPixels = 12.0;

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
  /// Множитель силы ветра: F = windageArea × v² × windForceFactor. При 5 м/с даёт ~6000 Н; тяга 10500 Н позволяет идти против ветра.
  static const double windForceFactor = 15.0;
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
  /// Множитель момента руля (Н·м на единицу потока). Подобран так, чтобы радиус разворота оставался приемлемым при увеличенной тяге.
  static const double rudderTorqueFactor = 1600.0;
  /// На заднем ходе руль действует «наоборот»; множитель >1 чтобы пересилить prop walk при повороте против заброса.
  static const double rudderReverseEffectiveness = 3;
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
  /// Муринг (ленивый конец): линейная жёсткость натяжения (как [mooringTensionLinear]).
  static const double lazyLineTensionLinear = 45.0;
  /// Муринг: квадратичная часть натяжения.
  static const double lazyLineTensionQuadratic = 0.2;
  /// Макс. длина муринга от носа до якоря (м).
  static const double lazyLineMaxLengthMeters = 80.0;
  /// Допуск угла для победы на уровнях 3/4 (градусы): яхта в пределах ±5° от целевого угла.
  static const double victoryAngleToleranceDegrees = 5.0;

  // --- ЯКОРЬ И ЦЕПЬ (уровень 4) ---
  /// Макс. длина якорной цепи (метры). При превышении — натяжение тянет нос к якорю.
  static const double anchorChainMaxLengthMeters = 30.0;
  /// Жёсткость якорной цепи (линейная).
  static const double anchorChainTensionLinear = 60.0;
  /// Жёсткость якорной цепи (квадратичная).
  static const double anchorChainTensionQuadratic = 0.3;
  /// Макс. натяжение цепи (пиксели) — ограничитель рывка.
  static const double anchorChainMaxTensionPixels = 1200.0;
  /// Демпфирование скорости при натяжении цепи (слабое).
  static const double anchorChainDampingLight = 0.96;
  /// Демпфирование при сильном натяжении цепи.
  static const double anchorChainDampingStrong = 0.88;
  /// Доля длины цепи, выше которой включается сильное демпфирование.
  static const double anchorChainStrainRatioForStrongDamping = 0.15;
  /// Радиус зоны сброса якоря (метры). Яхта должна быть в пределах этого радиуса от центра зоны.
  static const double anchorDropZoneRadiusMeters = 10.0;
  /// Радиус зоны сброса якоря в пикселях (совпадает с [anchorDropZoneRadiusMeters] × [pixelRatio]).
  static const double anchorDropZoneRadiusPixels = anchorDropZoneRadiusMeters * pixelRatio;
  /// Центральная точка зоны сброса якоря на карте (пиксели) — компактная заливка, без огромного диска.
  static const double anchorDropZoneCenterMarkerRadiusPixels = 14.0;
  /// Порог натяжения цепи (доля от maxLength), выше которого цепь рисуется красной.
  static const double anchorChainTensionWarningRatio = 0.85;
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
  /// Смещение точки крепления швартовых от диаметральной плоскости (доля ширины яхты, size.y).
  /// Меняет положение концов на борту. После изменения — полный перезапуск приложения (Hot Reload const не подхватывает).
  static const double ropeOffsetFromBoard = 0.22;
  /// Позиция носового крепления (доля длины от носа: 0.2 = 20% от носа).
  static const double ropeBowPositionFactor = 0.20;
  /// Позиция кормового крепления (0.95 от носа).
  static const double ropeSternPositionFactor = 0.90;
  /// Края кормы для уровня 3 (кормовой левый/правый): доля полуширины от центра (0.3 = края по полигону 0.2/0.8).
  static const double ropeSternEdgeFactor = 0.3;
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
  /// Минимальная длина каната (пиксели), при которой рисуется провисание; иначе — прямая (чтобы у причала все концы были видны).
  static const double ropeMinLengthForSagPixels = 8.0;

  // --- СВАИ (Baltic style, уровень 5) ---
  /// Радиус сваи (пиксели).
  static const double pileRadiusPixels = 0.5 * pixelRatio;

  // --- NARROW MARINA (уровни 6–9) ---
  /// Полуширина канала для alongside (ур. 6, лагом). Итого ширина прохода = 2 × значение.
  static const double narrowChannelHalfGapMeters = 6.0;
  /// Полуширина канала для nose-to (ур. 7–8, носом к причалу) — шире, т.к. яхты занимают длину в канале.
  static const double narrowChannelNoseToHalfGapMeters = 14.0;
  /// Полуширина канала nose-to только для ур. 9 (шире проход между понтонами).
  static const double narrowMarinaLevel9NoseToHalfGapMeters = 22.0;

  /// Полуширина канала (м) для узкой марины: alongside / nose-to по уровню.
  static double narrowChannelHalfGapMetersForLevel({
    required bool isAlongsideSetup,
    required int levelId,
  }) {
    if (isAlongsideSetup) return narrowChannelHalfGapMeters;
    if (levelId == 9) return narrowMarinaLevel9NoseToHalfGapMeters;
    return narrowChannelNoseToHalfGapMeters;
  }
  /// Количество яхт-препятствий на каждой стороне канала для alongside (ур. 6).
  static const int narrowChannelObstacleCount = 5;
  /// Количество яхт-препятствий на каждой стороне канала для nose-to (ур. 7–9).
  static const int narrowChannelNoseToObstacleCount = 8;
  /// Расстояние между центрами яхт вдоль понтона для alongside (ур. 6), метры.
  static const double narrowChannelObstacleSpacingMeters = 14.0;
  /// Расстояние между центрами яхт вдоль понтона для nose-to (ур. 7–9), метры.
  static const double narrowChannelNoseToObstacleSpacingMeters = 9.0;
  /// Смещение первой яхты от нижнего края причала (метры).
  static const double narrowChannelFirstObstacleOffsetMeters = 5.0;
  /// Ширина бокового понтона (finger dock) в узкой марине (метры).
  static const double narrowChannelDockWidthMeters = 10.0;
  /// Длина бокового понтона в узкой марине (метры) — от основного причала вниз по каналу.
  static const double narrowChannelDockLengthMeters = 70.0;
  /// Зазор между внутренней кромкой понтона и краем прохода (метры).
  static const double narrowChannelBoatZoneDepthMeters = 4.5;
  /// Запас (пиксели) при проверке пересечения препятствий с зелёной зоной швартовки (6–9).
  static const double narrowChannelGreenZoneObstaclePaddingPixels = 0.0;
  /// Ширина зелёной зоны узкой марины (6–9) в «ширинах яхты» — компактнее общего [greenZoneWidthInYachtWidths].
  static const double narrowMarinaGreenZoneWidthYachtWidths = 1.2;
  /// Высота зелёной зоны узкой марины: доля длины яхты ([YachtPlayer.size.x]).
  static const double narrowMarinaGreenZoneLengthFactor = 1.0;
  /// Уровень 6 (alongside у правого понтона): увеличенная длина зелёной зоны по сравнению с [narrowMarinaGreenZoneLengthFactor].
  static const double narrowMarinaLevel6GreenZoneLengthFactor = 1.35;
  /// Уровни 7–9 (nose-to): ширина зелёной зоны как доля длины яхты.
  static const double narrowMarinaNoseToGreenZoneLengthFactor = 1.2;
  /// Уровни 7–8 (nose-to): высота зелёной зоны в «ширинах яхты» (ось Y прямоугольника на понтоне).
  static const double narrowMarinaNoseToGreenZoneWidthYachtWidths = 1.4;
  /// Уровень 9: во сколько раз шире зона по той же оси, чем у ур. 7–8 (поверх [narrowMarinaNoseToGreenZoneWidthYachtWidths]).
  static const double narrowMarinaLevel9GreenZoneWidthScale = 1.5;
  /// Уровни 7–9 (nose-to): смещение зоны причаливания вверх (пиксели в мировых координатах).
  static const double narrowMarinaNoseToGreenZoneOffsetUpPixels = 30.0;
  /// Узкая марина: коэффициент для X точки напротив зелёной зоны (буй муринга ур. 7, зона якоря ур. 8)
  /// `k * slotCenterX - greenZoneCenterX`. При 2.0 — зеркало центра зелёной зоны относительно оси слота;
  /// меньшие значения сдвигают точку дальше в противоположную от причала сторону.
  static const double narrowMarinaLevel7MooringAnchorGreenZoneXFactor = 2.05;
}