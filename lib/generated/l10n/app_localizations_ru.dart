// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get gameTitle => 'Яхтенный симулятор';

  @override
  String get menuStartGame => 'Начать игру';

  @override
  String get menuSettings => 'Настройки';

  @override
  String get menuLevels => 'Уровни';

  @override
  String get menuQuit => 'Выход';

  @override
  String get controlThrottle => 'Газ';

  @override
  String get controlSteering => 'Руль';

  @override
  String get controlWind => 'Ветер';

  @override
  String get stateVictory => 'Победа!';

  @override
  String get stateGameOver => 'Игра окончена';

  @override
  String get stateMooredSuccessfully => 'Успешная швартовка';

  @override
  String get settingsSelectLanguage => 'Выбор языка';

  @override
  String get settingsSound => 'Звук';

  @override
  String get settingsMusic => 'Музыка';

  @override
  String briefingTitle(Object levelName) {
    return 'БРИФИНГ: $levelName';
  }

  @override
  String get briefingSessionSettings => 'НАСТРОЙКИ СЕССИИ';

  @override
  String get windStrength => 'СИЛА ВЕТРА:';

  @override
  String get propellerRightHanded => 'ВИНТ ПРАВОГО ШАГА:';

  @override
  String get yes => 'ДА';

  @override
  String get no => 'НЕТ';

  @override
  String get cancel => 'ОТМЕНА';

  @override
  String get startJourney => 'В ПУТЬ!';

  @override
  String get mooringBow => 'НОСОВОЙ';

  @override
  String get mooringStern => 'КОРМОВОЙ';

  @override
  String get mooringGiveBow => 'ПОДАТЬ НОСОВОЙ';

  @override
  String get mooringGiveStern => 'ПОДАТЬ КОРМОВОЙ';

  @override
  String get mooringForwardSpring => 'Шпринг носовой';

  @override
  String get mooringBackSpring => 'Шпринг кормовой';

  @override
  String get mooringGiveForwardSpring => 'Отдать шпринг носовой';

  @override
  String get mooringGiveBackSpring => 'Отдать шпринг кормовой';

  @override
  String get victoryTitle => 'УСПЕШНАЯ ШВАРТОВКА!';

  @override
  String get victoryMessage => 'Вы идеально закрепили судно.';

  @override
  String get victoryPlayAgain => 'ИГРАТЬ СНОВА';

  @override
  String get victoryNextLevel => 'СЛЕДУЮЩИЙ УРОВЕНЬ';

  @override
  String get victoryMessageShort => 'Судно надежно закреплено в порту.';

  @override
  String get victoryTitleDeparted => 'УСПЕШНЫЙ ОТХОД!';

  @override
  String get victoryMessageShortDeparted => 'Вы покинули причальную зону.';

  @override
  String get gameOverTitle => 'ПРОИСШЕСТВИЕ';

  @override
  String get gameOverRetry => 'ПЕРЕИГРАТЬ';

  @override
  String get gameOverMainMenu => 'В ГЛАВНОЕ МЕНЮ';

  @override
  String get levelSelectionTitle => 'СУДОВОЙ ЖУРНАЛ';

  @override
  String get statusWaiting => 'Ожидание команды...';

  @override
  String get statusBowSecured => 'Носовая отдана';

  @override
  String get statusSternSecured => 'Кормовая отдана';

  @override
  String get statusBowReleased => 'Носовая отдана';

  @override
  String get statusSternReleased => 'Кормовая отдана';

  @override
  String get statusForwardSpringSecured => 'Шпринг носовой отдан';

  @override
  String get statusBackSpringSecured => 'Шпринг кормовой отдан';

  @override
  String get statusForwardSpringReleased => 'Шпринг носовой отдан';

  @override
  String get statusBackSpringReleased => 'Шпринг кормовой отдан';

  @override
  String get statusAllLinesSecured => 'Все концы заведены. Отдайте и отходите.';

  @override
  String get statusLevelRestarted => 'Уровень перезапущен';

  @override
  String get statusMissionAccomplished => 'МИССИЯ ВЫПОЛНЕНА';

  @override
  String get statusFailed => 'ПРОВАЛ';

  @override
  String statusRiverFlow(String speed) {
    return 'Течение: $speed уз';
  }

  @override
  String get statusHighSeas => 'Открытое море. Держите позицию.';

  @override
  String get crashNose => 'КРИТИЧНО: Столкновение носом!';

  @override
  String get crashSide => 'АВАРИЯ: Слишком сильный удар бортом.';

  @override
  String get level1Name => 'Первый причал';

  @override
  String get level1Description =>
      'Тихая марина. Запаркуйте яхту в свободный слот между другими судами.';

  @override
  String get level2Name => 'Отход лагом';

  @override
  String get level2Description => 'Яхта стоит лагом. Отдайте концы и отойдите.';

  @override
  String get levelSettingsTitle => 'Настройки уровня';

  @override
  String get sectionWind => 'ВЕТЕР';

  @override
  String get sectionCurrent => 'ТЕЧЕНИЕ';

  @override
  String get sectionPropeller => 'ЗАБРОС ВИНТА';

  @override
  String get labelStrength => 'Сила';

  @override
  String get labelDirection => 'Направление';

  @override
  String get labelSpeed => 'Скорость';

  @override
  String get propellerRight => 'Правый';

  @override
  String get propellerLeft => 'Левый';

  @override
  String get buttonBack => 'НАЗАД';

  @override
  String get compassN => 'С';

  @override
  String get compassNE => 'СВ';

  @override
  String get compassE => 'В';

  @override
  String get compassSE => 'ЮВ';

  @override
  String get compassS => 'Ю';

  @override
  String get compassSW => 'ЮЗ';

  @override
  String get compassW => 'З';

  @override
  String get compassNW => 'СЗ';
}
