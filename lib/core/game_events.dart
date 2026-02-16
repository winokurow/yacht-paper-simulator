/// Базовый тип игрового события (столкновение, победа и т.д.).
/// Обработка в [YachtMasterGame] разгружает компоненты от прямой связи с игрой.
abstract class GameEvent {
  const GameEvent();
}

/// Авария: столкновение носом или бортом на высокой скорости.
class CrashEvent extends GameEvent {
  final String message;

  const CrashEvent(this.message);
}
