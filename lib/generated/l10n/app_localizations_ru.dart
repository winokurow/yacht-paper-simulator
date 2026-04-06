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
  String get statusMooringGetCloser => 'Подойдите ближе к бую муринга';

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
  String get level3Name => 'Кормой к причалу';

  @override
  String get level3Description =>
      'Швартовка кормой: кормовой левый, кормовой правый и муринг к якорю. Боковой ветер.';

  @override
  String get mooringSternPort => 'КОРМОВОЙ ЛЕВЫЙ';

  @override
  String get mooringSternStarboard => 'КОРМОВОЙ ПРАВЫЙ';

  @override
  String get mooringLazyLine => 'МУРИНГ';

  @override
  String get mooringGiveSternPort => 'Отдать кормовой левый';

  @override
  String get mooringGiveSternStarboard => 'Отдать кормовой правый';

  @override
  String get mooringGiveLazyLine => 'Отдать муринг';

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

  @override
  String get level4Name => 'Кормой с якорем';

  @override
  String get level4Description =>
      'Сбросьте якорь в обозначенной зоне, подойдите задним ходом к причалу и закрепите два кормовых конца.';

  @override
  String get controlDropAnchor => 'ОТДАТЬ ЯКОРЬ';

  @override
  String get statusAnchorGetCloser => 'Войдите в зелёную зону для сброса якоря';

  @override
  String get statusAnchorDropped => 'Якорь отдан!';

  @override
  String get level5Name => 'Балтийская швартовка';

  @override
  String get level5Description =>
      'Войдите носом между четырёх свай и закрепите носовые на причале.';

  @override
  String get mooringAftPilePort => 'КОРМ. ЛЕВАЯ СВАЯ';

  @override
  String get mooringAftPileStarboard => 'КОРМ. ПРАВАЯ СВАЯ';

  @override
  String get mooringBowPort => 'НОСОВОЙ ЛЕВЫЙ';

  @override
  String get mooringBowStarboard => 'НОСОВОЙ ПРАВЫЙ';

  @override
  String get mooringGiveAftPilePort => 'Отдать кормовую левую сваю';

  @override
  String get mooringGiveAftPileStarboard => 'Отдать кормовую правую сваю';

  @override
  String get mooringGiveBowPort => 'Отдать носовой левый';

  @override
  String get mooringGiveBowStarboard => 'Отдать носовой правый';

  @override
  String get level6Name => 'Узкая марина — лагом';

  @override
  String get level6Description =>
      'Проведите яхту по узкому каналу между лодками и пришвартуйтесь лагом.';

  @override
  String get level7Name => 'Узкая марина — кормой с мурингом';

  @override
  String get level7Description =>
      'Пройдите канал и встаньте кормой к причалу с мурингом. Сильный боковой ветер.';

  @override
  String get level8Name => 'Узкая марина — кормой с якорем';

  @override
  String get level8Description =>
      'Сбросьте якорь в канале, подойдите задним ходом к причалу и закрепите два кормовых.';

  @override
  String get level9Name => 'Узкая марина — балтийская';

  @override
  String get level9Description =>
      'Войдите носом в узкий канал и закрепите все четыре конца на сваях.';

  @override
  String get levelInstructionTitle => 'Инструкция к уровню';

  @override
  String get levelInstructionTooltip => 'Подсказка по уровню';

  @override
  String get levelInstruction1 =>
      '• W/S — газ, A/D — руль.\n• Зайдите в зелёную зону между яхтами и остановитесь у тумб носом и кормой.\n• Когда появятся кнопки, отдайте носовой и кормовой швартовые.\n• Победа: оба конца закреплены, малая скорость.';

  @override
  String get levelInstruction2 =>
      '• Старт с уже заведёнными четырьмя концами.\n• Отдайте нос, корму и оба шпринга, когда готовы к отходу.\n• Победа: все концы свободны и яхта покинула зелёную зону.';

  @override
  String get levelInstruction3 =>
      '• Кормой к причалу: буй муринга напротив зелёной зоны.\n• Закрепите кормовые порт и старборд, затем ленивый конец к бую.\n• Победа: оба кормовых и муринг, нужный курс, почти остановка.';

  @override
  String get levelInstruction4 =>
      '• Войдите в зелёный круг и отдайте якорь по кнопке.\n• Задним ходом к причалу и два кормовых на тумбы.\n• Победа: якорь отдан, оба кормовых, курс и малая скорость.';

  @override
  String get levelInstruction5 =>
      '• Носом между четырьмя сваями; кормовые — к задним сваям, носовые — к тумбам на причале.\n• Обычно: сначала корма, потом нос.\n• Победа: четыре конца, нос перпендикулярен причалу, остановка.';

  @override
  String get levelInstruction6 =>
      '• Пройдите узкий канал, не задевая яхты.\n• Встаньте лагом у правого понтона; зелёный прямоугольник — место стоянки.\n• Победа: нос и корма на швартовых, малая скорость.';

  @override
  String get levelInstruction7 =>
      '• Пройдите канал, развернитесь кормой к правому понтону.\n• Буй напротив зелёной зоны: сначала кормовые, затем ленивый конец.\n• Победа: оба кормовых и муринг, курс и скорость в норме.';

  @override
  String get levelInstruction8 =>
      '• Сбросьте якорь в зелёном кольце в канале, затем задним ходом к причалу.\n• Два кормовых: порт к нижнему тумбе, старборд к верхнему вдоль понтона.\n• Победа: якорь, оба кормовых, курс, остановка.';

  @override
  String get levelInstruction9 =>
      '• Носом в слот; четыре сваи по углам зелёной зоны — не наезжайте на них.\n• Кормовые к сваям со стороны канала, носовые к сваям у причала.\n• Победа: четыре конца, нос к понтону, остановка.';
}
