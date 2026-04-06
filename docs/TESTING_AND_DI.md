# Тестирование и внедрение зависимостей (DI)

## Модульные тесты физики

В `test/yacht_physics_test.dart` покрыты:

- **YachtPhysics** (статические методы): нулевой throttle, сопротивление воды (в т.ч. доминирование v²), максимальные углы руля, эффективный поток на высокой скорости, `stop()` и проверка callback через mocktail.
- **YachtDynamics**: нулевой ввод (затухание скорости и effectiveThrust), ограничение угловой скорости при полном руле, плавный поворот руля, граничные случаи (dt > 0.1, ограничение скорости, течение).
- **Столкновения** (логика из `resolveCollisionOutcome`): высокая скорость + нос → noseCrash, высокая скорость + борт → sideCrash, низкая скорость → soft, порог `maxSafeImpactSpeed`.

Физика не зависит от `YachtGame` и Flame, тесты выполняются без запуска движка.

## Рекомендация по DI для YachtMasterGame

Если понадобится тестировать игровой цикл или сценарии без реального движка:

1. **Внедрение YachtDynamics**  
   В конструктор `YachtMasterGame` добавить опциональный параметр `YachtDynamics? dynamics`. При создании `YachtPlayer` передавать в него `dynamics ?? YachtDynamics()`. В тестах подставлять экземпляр с нужным `pixelRatio` или (при необходимости) подменять константы через отдельный конфиг.

2. **Колбэк событий**  
   Уже есть: `YachtPlayer.onGameEvent` задаётся снаружи (в `startLevel` и в тестовой игре). Этого достаточно, чтобы проверять срабатывание `CrashEvent` без вызова `pauseEngine()` и оверлеев — в тестах подменять обработчик.

3. **Окружение (ветер, течение)**  
   `YachtEnvironment` создаётся в `YachtPlayer.update()` из `game.activeWindSpeed` и т.д. Для изоляции можно ввести интерфейс `YachtEnvironmentProvider` с методами `double get windSpeed`, `double get windDirection` и т.д., а в игре передавать реализацию, в тестах — mock/fake.

Запуск тестов физики:

```bash
flutter test test/yacht_physics_test.dart
```
