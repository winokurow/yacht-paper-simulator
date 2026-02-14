// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get gameTitle => 'Yacht Paper Simulator';

  @override
  String get menuStartGame => 'Start Game';

  @override
  String get menuSettings => 'Settings';

  @override
  String get menuLevels => 'Levels';

  @override
  String get menuQuit => 'Quit';

  @override
  String get controlThrottle => 'Throttle';

  @override
  String get controlSteering => 'Steering';

  @override
  String get controlWind => 'Wind';

  @override
  String get stateVictory => 'Victory!';

  @override
  String get stateGameOver => 'Game Over';

  @override
  String get stateMooredSuccessfully => 'Moored Successfully';

  @override
  String get settingsSelectLanguage => 'Select Language';

  @override
  String get settingsSound => 'Sound';

  @override
  String get settingsMusic => 'Music';

  @override
  String briefingTitle(String levelName) {
    return 'BRIEFING: $levelName';
  }

  @override
  String get briefingSessionSettings => 'SESSION SETTINGS';

  @override
  String get windStrength => 'WIND STRENGTH:';

  @override
  String get propellerRightHanded => 'RIGHT-HAND PROPELLER:';

  @override
  String get yes => 'YES';

  @override
  String get no => 'NO';

  @override
  String get cancel => 'CANCEL';

  @override
  String get startJourney => 'SET SAIL!';

  @override
  String get mooringBow => 'BOW';

  @override
  String get mooringStern => 'STERN';

  @override
  String get mooringGiveBow => 'MOOR BOW';

  @override
  String get mooringGiveStern => 'MOOR STERN';

  @override
  String get victoryTitle => 'SUCCESSFUL MOORING!';

  @override
  String get victoryMessage => 'You have secured the vessel perfectly.';

  @override
  String get victoryPlayAgain => 'PLAY AGAIN';

  @override
  String get victoryNextLevel => 'NEXT LEVEL';

  @override
  String get victoryMessageShort => 'Vessel securely moored.';

  @override
  String get gameOverTitle => 'INCIDENT';

  @override
  String get gameOverRetry => 'RETRY';

  @override
  String get gameOverMainMenu => 'MAIN MENU';

  @override
  String get levelSelectionTitle => 'SHIP\'S LOG';
}
