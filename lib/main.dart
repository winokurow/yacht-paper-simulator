import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yacht/ui/level_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const YachtApp());
}

/// Корневой виджет приложения (для integration_test и тестов).
class YachtApp extends StatelessWidget {
  const YachtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Yacht Master',
      theme: ThemeData(
        fontFamily: 'monospace',
        primarySwatch: Colors.brown,
      ),
      home: const LevelSelectionScreen(),
    );
  }
}
