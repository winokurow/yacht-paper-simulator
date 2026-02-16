// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get gameTitle => 'Yacht Simulator';

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
  String get stateMooredSuccessfully => 'Moored successfully';

  @override
  String get settingsSelectLanguage => 'Select Language';

  @override
  String get settingsSound => 'Sound';

  @override
  String get settingsMusic => 'Music';

  @override
  String briefingTitle(Object levelName) {
    return 'BRIEFING: $levelName';
  }

  @override
  String get briefingSessionSettings => 'SESSION SETTINGS';

  @override
  String get windStrength => 'WIND STRENGTH:';

  @override
  String get propellerRightHanded => 'RIGHT-HANDED PROPELLER:';

  @override
  String get yes => 'YES';

  @override
  String get no => 'NO';

  @override
  String get cancel => 'CANCEL';

  @override
  String get startJourney => 'START JOURNEY!';

  @override
  String get mooringBow => 'BOW LINE';

  @override
  String get mooringStern => 'STERN LINE';

  @override
  String get mooringGiveBow => 'GIVE BOW LINE';

  @override
  String get mooringGiveStern => 'GIVE STERN LINE';

  @override
  String get victoryTitle => 'MOORED SUCCESSFULLY!';

  @override
  String get victoryMessage => 'You have secured the vessel perfectly.';

  @override
  String get victoryPlayAgain => 'PLAY AGAIN';

  @override
  String get victoryNextLevel => 'NEXT LEVEL';

  @override
  String get victoryMessageShort => 'The vessel is safely secured in the port.';

  @override
  String get gameOverTitle => 'INCIDENT';

  @override
  String get gameOverRetry => 'RETRY';

  @override
  String get gameOverMainMenu => 'MAIN MENU';

  @override
  String get levelSelectionTitle => 'LOGBOOK';

  @override
  String get statusWaiting => 'Waiting for command...';

  @override
  String get statusBowSecured => 'Bow line secured';

  @override
  String get statusSternSecured => 'Stern line secured';

  @override
  String get statusLevelRestarted => 'Level restarted';

  @override
  String get statusMissionAccomplished => 'MISSION ACCOMPLISHED';

  @override
  String get statusFailed => 'FAILED';

  @override
  String statusRiverFlow(String speed) {
    return 'Current: $speed kn';
  }

  @override
  String get statusHighSeas => 'Open sea. Hold position.';

  @override
  String get crashNose => 'CRITICAL: Bow collision!';

  @override
  String get crashSide => 'CRASH: Excessive side impact.';

  @override
  String get level1Name => 'First Pier';

  @override
  String get level1Description =>
      'A quiet marina. Park the yacht in the empty slot between other vessels.';

  @override
  String get level2Name => 'Seine Current';

  @override
  String get level2Description =>
      'Challenging mooring on a river with a strong side current.';

  @override
  String get levelSettingsTitle => 'Level Settings';

  @override
  String get sectionWind => 'WIND';

  @override
  String get sectionCurrent => 'CURRENT';

  @override
  String get sectionPropeller => 'PROPELLER WALK';

  @override
  String get labelStrength => 'Strength';

  @override
  String get labelDirection => 'Direction';

  @override
  String get labelSpeed => 'Speed';

  @override
  String get propellerRight => 'Right';

  @override
  String get propellerLeft => 'Left';

  @override
  String get buttonBack => 'BACK';

  @override
  String get compassN => 'N';

  @override
  String get compassNE => 'NE';

  @override
  String get compassE => 'E';

  @override
  String get compassSE => 'SE';

  @override
  String get compassS => 'S';

  @override
  String get compassSW => 'SW';

  @override
  String get compassW => 'W';

  @override
  String get compassNW => 'NW';
}
