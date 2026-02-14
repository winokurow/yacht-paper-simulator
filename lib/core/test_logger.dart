import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:yacht/components/yacht_player.dart';

class TestLogger {
static final List<String> _logs = [];

static void logEvent(String type, LogicalKeyboardKey key, double time, YachtPlayer yacht) {
  final pos = yacht.position;
  final vel = yacht.velocity;
  final angle = yacht.angle;

  // Добавляем tester и game в начало строки
  _logs.add(
      'await runStep(tester, game, t: ${time.toStringAsFixed(3)}, action: "$type", key: ${_formatKey(key)}, '
          'px: ${pos.x.toStringAsFixed(2)}, py: ${pos.y.toStringAsFixed(2)}, '
          'ang: ${angle.toStringAsFixed(4)}, vx: ${vel.x.toStringAsFixed(2)}, vy: ${vel.y.toStringAsFixed(2)});'
  );

  print('Logged: $type ${key.debugName} at $time');
}

static String _formatKey(LogicalKeyboardKey key) {
if (key == LogicalKeyboardKey.keyW) return 'LogicalKeyboardKey.keyW';
if (key == LogicalKeyboardKey.keyS) return 'LogicalKeyboardKey.keyS';
if (key == LogicalKeyboardKey.keyA) return 'LogicalKeyboardKey.keyA';
if (key == LogicalKeyboardKey.keyD) return 'LogicalKeyboardKey.keyD';
return 'LogicalKeyboardKey.space';
}

static void printFinalBlock() {
print('\n🚀 --- [NEW TIMELINE LOG] ---');
print(_logs.join('\n'));
print('-----------------------------\n');
_logs.clear();
}
}