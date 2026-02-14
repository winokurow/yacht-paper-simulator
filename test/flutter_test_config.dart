import 'package:golden_toolkit/golden_toolkit.dart';

/// Конфигурация тестов: загрузка шрифтов приложения для golden-тестов.
Future<void> testExecutable(Future<void> Function() testMain) async {
  await loadAppFonts();
  return testMain();
}
