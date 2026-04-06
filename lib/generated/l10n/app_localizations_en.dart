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
  String get mooringBow => 'bow line';

  @override
  String get mooringStern => 'stern line';

  @override
  String get mooringGiveBow => 'Give bow line';

  @override
  String get mooringGiveStern => 'Give stern line';

  @override
  String get mooringForwardSpring => 'Forward Spring';

  @override
  String get mooringBackSpring => 'Back Spring';

  @override
  String get mooringGiveForwardSpring => 'Give Forward Spring';

  @override
  String get mooringGiveBackSpring => 'Give Back Spring';

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
  String get victoryTitleDeparted => 'SUCCESSFUL DEPARTURE!';

  @override
  String get victoryMessageShortDeparted => 'You have left the mooring zone.';

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
  String get statusMooringGetCloser => 'Get closer to the mooring buoy';

  @override
  String get statusBowReleased => 'Bow line released';

  @override
  String get statusSternReleased => 'Stern line released';

  @override
  String get statusForwardSpringSecured => 'Forward spring secured';

  @override
  String get statusBackSpringSecured => 'Back spring secured';

  @override
  String get statusForwardSpringReleased => 'Forward spring released';

  @override
  String get statusBackSpringReleased => 'Back spring released';

  @override
  String get statusAllLinesSecured => 'All lines secured. Release to depart.';

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
  String get level2Name => 'Departure Alongside';

  @override
  String get level2Description => 'Yacht is moored alongside with 4 lines.';

  @override
  String get level3Name => 'Stern-to Mooring';

  @override
  String get level3Description =>
      'Moor stern-to: stern port, stern starboard, and lazy line to anchor. Side wind.';

  @override
  String get mooringSternPort => 'STERN PORT';

  @override
  String get mooringSternStarboard => 'STERN STARBOARD';

  @override
  String get mooringLazyLine => 'MOORING LINE';

  @override
  String get mooringGiveSternPort => 'Give stern port';

  @override
  String get mooringGiveSternStarboard => 'Give stern starboard';

  @override
  String get mooringGiveLazyLine => 'Give mooring line';

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

  @override
  String get level4Name => 'Stern-to with Anchor';

  @override
  String get level4Description =>
      'Drop anchor in the designated zone, back up to the pier, and secure two stern lines.';

  @override
  String get controlDropAnchor => 'DROP ANCHOR';

  @override
  String get statusAnchorGetCloser => 'Enter the green zone to drop anchor';

  @override
  String get statusAnchorDropped => 'Anchor dropped!';

  @override
  String get level5Name => 'Baltic Mooring';

  @override
  String get level5Description =>
      'Moor bow-first between four piles, then secure bow lines to the dock.';

  @override
  String get mooringAftPilePort => 'AFT PORT PILE';

  @override
  String get mooringAftPileStarboard => 'AFT STBD PILE';

  @override
  String get mooringBowPort => 'BOW PORT';

  @override
  String get mooringBowStarboard => 'BOW STARBOARD';

  @override
  String get mooringGiveAftPilePort => 'Release aft port pile';

  @override
  String get mooringGiveAftPileStarboard => 'Release aft stbd pile';

  @override
  String get mooringGiveBowPort => 'Release bow port';

  @override
  String get mooringGiveBowStarboard => 'Release bow starboard';

  @override
  String get level6Name => 'Narrow Alongside';

  @override
  String get level6Description =>
      'Navigate a tight channel lined with moored yachts and park alongside.';

  @override
  String get level7Name => 'Narrow Stern-to Mooring';

  @override
  String get level7Description =>
      'Thread the channel and moor stern-to with a mooring line. Strong side wind.';

  @override
  String get level8Name => 'Narrow Stern-to Anchor';

  @override
  String get level8Description =>
      'Drop anchor in the channel, then reverse to the pier and secure two stern lines.';

  @override
  String get level9Name => 'Narrow Baltic Mooring';

  @override
  String get level9Description =>
      'Enter a narrow channel bow-first and secure all four lines to the piles.';

  @override
  String get levelInstructionTitle => 'Level briefing';

  @override
  String get levelInstructionTooltip => 'Instructions for this level';

  @override
  String get levelInstruction1 =>
      '• W/S — throttle, A/D — rudder.\n• Move into the green berth between moored yachts and stop with bow and stern near the bollards.\n• When the buttons appear, give bow and stern lines.\n• Win: both lines secured and low speed.';

  @override
  String get levelInstruction2 =>
      '• You start with four lines already made fast.\n• Release bow, stern, and both springs when you are ready to depart.\n• Win: all lines are free and the yacht has left the green zone.';

  @override
  String get levelInstruction3 =>
      '• Stern-to: approach the pier astern; the mooring buoy lies opposite the green zone.\n• Secure stern port and stern starboard, then the lazy line to the buoy.\n• Win: both stern lines and the lazy line secured, correct heading, nearly stopped.';

  @override
  String get levelInstruction4 =>
      '• Enter the green anchor circle and drop anchor when prompted.\n• Back toward the pier and secure two stern lines to the bollards.\n• Win: anchor down, both stern lines fast, correct heading, low speed.';

  @override
  String get levelInstruction5 =>
      '• Bow-first between the four piles. Aft lines to the aft piles; bow lines to the dock bollards.\n• Typical order: aft port and starboard, then bow port and starboard.\n• Win: all four lines, bow perpendicular to the dock, stopped.';

  @override
  String get levelInstruction6 =>
      '• Thread the narrow channel without hitting moored yachts.\n• Park alongside the right finger; the green rectangle is your berth.\n• Win: bow and stern lines secured, low speed.';

  @override
  String get levelInstruction7 =>
      '• Pass the channel, then reverse stern-to to the right finger.\n• Mooring buoy mirrors the green zone; stern lines first, then the lazy line to the buoy.\n• Win: both sterns and lazy line secured, heading and speed in range.';

  @override
  String get levelInstruction8 =>
      '• Drop anchor inside the green ring in the channel, then reverse to the pier.\n• Two stern lines: port to the lower bollard, starboard to the upper (along the finger).\n• Win: anchor down, both sterns fast, correct heading, stopped.';

  @override
  String get levelInstruction9 =>
      '• Bow-first into the slot; four piles sit at the green zone corners — do not ram them.\n• Aft lines to the channel-side piles, bow lines to the pier-side piles.\n• Win: all four lines, bow toward the finger, stopped.';
}
