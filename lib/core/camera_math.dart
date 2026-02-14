import 'package:flame/extensions.dart';
import 'constants.dart';

/// Чистые функции расчёта камеры (зум, позиция).
class CameraMath {
  CameraMath._();

  static const double viewportHeight = 720.0;
  static const double zoomMin = 0.08;
  static const double zoomMax = 0.6;
  static const double zoomClampMin = 0.12;
  static const double zoomClampMax = 0.5;
  static const double minVisibleHeightMeters = 15.0;
  static const double dockFillRatio = 0.85;
  static const double yachtFillRatio = 0.8;
  /// Скорость лерпа зума камеры (1/с).
  static const double zoomLerpSpeed = 2.0;

  /// Целевой зум, чтобы расстояние до причала занимало долю экрана.
  static double targetZoomFromDistanceToDock(double distanceToDockPixels) {
    double visibleHeight = distanceToDockPixels / dockFillRatio;
    double minVisiblePixels = minVisibleHeightMeters * Constants.pixelRatio;
    if (visibleHeight < minVisiblePixels) visibleHeight = minVisiblePixels;
    return (viewportHeight / visibleHeight).clamp(zoomMin, zoomMax);
  }

  /// Целевой зум для "умной" камеры (яхта в нижней части, причал сверху).
  static double targetZoomSmart(double distancePixels) {
    double targetZoom = viewportHeight / (distancePixels / yachtFillRatio);
    return targetZoom.clamp(zoomClampMin, zoomClampMax);
  }

  /// Целевая Y-позиция камеры: причал прижат к верху вьюпорта.
  static double targetCameraY(double dockY, double currentWorldHeight) {
    return dockY + (currentWorldHeight / 2);
  }

  /// Текущая видимая высота мира при заданном зуме.
  static double worldHeightAtZoom(double zoom) => viewportHeight / zoom;
}
