# Интеграционные (E2E) тесты Yacht Simulator

Запуск полного приложения и сценариев «игрок за клавиатурой» + проверка Win/Loss и UI.

## Запуск

```bash
# Указать устройство (иначе Flutter попросит выбрать)
flutter test integration_test/app_test.dart -d windows

# Или для Android/iOS
flutter test integration_test/app_test.dart -d <device_id>
```

## Сценарии

1. **Успешная швартовка** — выбор уровня 1, разгон (W 2 с), поворот (D), ожидание зоны швартовки (< 10 м), тап «ПОДАТЬ НОСОВОЙ» / «ПОДАТЬ КОРМОВОЙ», проверка текста "MISSION ACCOMPLISHED" и оверлея Victory.
2. **Крушение** — полный газ (W), направление в причал, проверка скорости ≈ 0, оверлей GameOver и текст про столкновение.
3. **Зум и стресс** — движение, проверка что `camera.viewfinder.zoom` в допустимом диапазоне и без NaN/Infinity; тап «Назад» на ходу — приложение не падает.

## Доступ к игре из теста

Игра доступна по ключу `yacht_game_widget` (см. `lib/game/game_view.dart`). В тесте используется `getGameFromTree(tester)` для доступа к `YachtMasterGame` (яхта, камера, оверлеи).

## Управление яхтой в тесте

В тестовой среде `HardwareKeyboard.instance.logicalKeysPressed` не обновляется от `sendKeyDownEvent`, поэтому движение задаётся напрямую: **`driveYacht(tester, throttle: 1.0, rudder: 0.8, duration: ...)`** — выставляет `game.yacht.targetThrottle` и `targetRudderAngle`, затем крутит `pump()` на заданное время. Физика и победа/проигрыш проверяются как в игре. `holdKey`/`tapKey` оставлены для сценариев, где клавиатура заработает (например, на устройстве).
