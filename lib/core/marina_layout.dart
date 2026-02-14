import 'package:flame/extensions.dart';
import '../model/level_config.dart';
import 'constants.dart';

/// Параметры раскладки причала (чистые данные).
class MarinaLayoutParams {
  final double slipWidthMeters;
  final double edgePaddingMeters;
  final int slotCount;

  const MarinaLayoutParams({
    this.slipWidthMeters = 15.0,
    this.edgePaddingMeters = 18.0,
    required this.slotCount,
  });

  double get slipStepPixels => slipWidthMeters * Constants.pixelRatio;
  double get edgePaddingPixels => edgePaddingMeters * Constants.pixelRatio;
  double get dockWidthPixels => (slipStepPixels * slotCount) + (edgePaddingPixels * 2);
}

/// Чистые функции расчёта геометрии причала и позиций.
class MarinaLayout {
  MarinaLayout._();

  /// Параметры по умолчанию для списка лодок.
  static MarinaLayoutParams paramsForLayout(List<BoatPlacement> marinaLayout) {
    return MarinaLayoutParams(slotCount: marinaLayout.length);
  }

  /// X-позиция левого края причала (центр по миру).
  static double dockX(double dockWidthPixels, double playAreaWidth) {
    return (playAreaWidth / 2) - (dockWidthPixels / 2);
  }

  /// X-позиции тумб для слота игрока [пиксели от левого края причала].
  static List<double> playerBollardXPositions(
    List<BoatPlacement> marinaLayout,
    double slipStepPixels,
    double edgePaddingPixels,
  ) {
    for (int i = 0; i < marinaLayout.length; i++) {
      if (marinaLayout[i].type == 'player_slot') {
        double slotLeft = edgePaddingPixels + (i * slipStepPixels);
        return [
          slotLeft + (slipStepPixels * 0.2),
          slotLeft + (slipStepPixels * 0.8),
        ];
      }
    }
    return [];
  }

  /// X-позиция центра слота i (в мировых координатах: dockX + локальный offset).
  static double slotCenterX(
    double dockX,
    double edgePaddingPixels,
    double slipStepPixels,
    int index,
  ) {
    return dockX + edgePaddingPixels + (index * slipStepPixels) + (slipStepPixels / 2);
  }
}
