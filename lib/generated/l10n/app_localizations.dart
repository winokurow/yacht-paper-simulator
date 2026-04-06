import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @gameTitle.
  ///
  /// In en, this message translates to:
  /// **'Yacht Simulator'**
  String get gameTitle;

  /// No description provided for @menuStartGame.
  ///
  /// In en, this message translates to:
  /// **'Start Game'**
  String get menuStartGame;

  /// No description provided for @menuSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get menuSettings;

  /// No description provided for @menuLevels.
  ///
  /// In en, this message translates to:
  /// **'Levels'**
  String get menuLevels;

  /// No description provided for @menuQuit.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get menuQuit;

  /// No description provided for @controlThrottle.
  ///
  /// In en, this message translates to:
  /// **'Throttle'**
  String get controlThrottle;

  /// No description provided for @controlSteering.
  ///
  /// In en, this message translates to:
  /// **'Steering'**
  String get controlSteering;

  /// No description provided for @controlWind.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get controlWind;

  /// No description provided for @stateVictory.
  ///
  /// In en, this message translates to:
  /// **'Victory!'**
  String get stateVictory;

  /// No description provided for @stateGameOver.
  ///
  /// In en, this message translates to:
  /// **'Game Over'**
  String get stateGameOver;

  /// No description provided for @stateMooredSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Moored successfully'**
  String get stateMooredSuccessfully;

  /// No description provided for @settingsSelectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get settingsSelectLanguage;

  /// No description provided for @settingsSound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get settingsSound;

  /// No description provided for @settingsMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get settingsMusic;

  /// No description provided for @briefingTitle.
  ///
  /// In en, this message translates to:
  /// **'BRIEFING: {levelName}'**
  String briefingTitle(Object levelName);

  /// No description provided for @briefingSessionSettings.
  ///
  /// In en, this message translates to:
  /// **'SESSION SETTINGS'**
  String get briefingSessionSettings;

  /// No description provided for @windStrength.
  ///
  /// In en, this message translates to:
  /// **'WIND STRENGTH:'**
  String get windStrength;

  /// No description provided for @propellerRightHanded.
  ///
  /// In en, this message translates to:
  /// **'RIGHT-HANDED PROPELLER:'**
  String get propellerRightHanded;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'YES'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'NO'**
  String get no;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get cancel;

  /// No description provided for @startJourney.
  ///
  /// In en, this message translates to:
  /// **'START JOURNEY!'**
  String get startJourney;

  /// No description provided for @mooringBow.
  ///
  /// In en, this message translates to:
  /// **'bow line'**
  String get mooringBow;

  /// No description provided for @mooringStern.
  ///
  /// In en, this message translates to:
  /// **'stern line'**
  String get mooringStern;

  /// No description provided for @mooringGiveBow.
  ///
  /// In en, this message translates to:
  /// **'Give bow line'**
  String get mooringGiveBow;

  /// No description provided for @mooringGiveStern.
  ///
  /// In en, this message translates to:
  /// **'Give stern line'**
  String get mooringGiveStern;

  /// No description provided for @mooringForwardSpring.
  ///
  /// In en, this message translates to:
  /// **'Forward Spring'**
  String get mooringForwardSpring;

  /// No description provided for @mooringBackSpring.
  ///
  /// In en, this message translates to:
  /// **'Back Spring'**
  String get mooringBackSpring;

  /// No description provided for @mooringGiveForwardSpring.
  ///
  /// In en, this message translates to:
  /// **'Give Forward Spring'**
  String get mooringGiveForwardSpring;

  /// No description provided for @mooringGiveBackSpring.
  ///
  /// In en, this message translates to:
  /// **'Give Back Spring'**
  String get mooringGiveBackSpring;

  /// No description provided for @victoryTitle.
  ///
  /// In en, this message translates to:
  /// **'MOORED SUCCESSFULLY!'**
  String get victoryTitle;

  /// No description provided for @victoryMessage.
  ///
  /// In en, this message translates to:
  /// **'You have secured the vessel perfectly.'**
  String get victoryMessage;

  /// No description provided for @victoryPlayAgain.
  ///
  /// In en, this message translates to:
  /// **'PLAY AGAIN'**
  String get victoryPlayAgain;

  /// No description provided for @victoryNextLevel.
  ///
  /// In en, this message translates to:
  /// **'NEXT LEVEL'**
  String get victoryNextLevel;

  /// No description provided for @victoryMessageShort.
  ///
  /// In en, this message translates to:
  /// **'The vessel is safely secured in the port.'**
  String get victoryMessageShort;

  /// No description provided for @victoryTitleDeparted.
  ///
  /// In en, this message translates to:
  /// **'SUCCESSFUL DEPARTURE!'**
  String get victoryTitleDeparted;

  /// No description provided for @victoryMessageShortDeparted.
  ///
  /// In en, this message translates to:
  /// **'You have left the mooring zone.'**
  String get victoryMessageShortDeparted;

  /// No description provided for @gameOverTitle.
  ///
  /// In en, this message translates to:
  /// **'INCIDENT'**
  String get gameOverTitle;

  /// No description provided for @gameOverRetry.
  ///
  /// In en, this message translates to:
  /// **'RETRY'**
  String get gameOverRetry;

  /// No description provided for @gameOverMainMenu.
  ///
  /// In en, this message translates to:
  /// **'MAIN MENU'**
  String get gameOverMainMenu;

  /// No description provided for @levelSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'LOGBOOK'**
  String get levelSelectionTitle;

  /// No description provided for @statusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for command...'**
  String get statusWaiting;

  /// No description provided for @statusBowSecured.
  ///
  /// In en, this message translates to:
  /// **'Bow line secured'**
  String get statusBowSecured;

  /// No description provided for @statusSternSecured.
  ///
  /// In en, this message translates to:
  /// **'Stern line secured'**
  String get statusSternSecured;

  /// No description provided for @statusMooringGetCloser.
  ///
  /// In en, this message translates to:
  /// **'Get closer to the mooring buoy'**
  String get statusMooringGetCloser;

  /// No description provided for @statusBowReleased.
  ///
  /// In en, this message translates to:
  /// **'Bow line released'**
  String get statusBowReleased;

  /// No description provided for @statusSternReleased.
  ///
  /// In en, this message translates to:
  /// **'Stern line released'**
  String get statusSternReleased;

  /// No description provided for @statusForwardSpringSecured.
  ///
  /// In en, this message translates to:
  /// **'Forward spring secured'**
  String get statusForwardSpringSecured;

  /// No description provided for @statusBackSpringSecured.
  ///
  /// In en, this message translates to:
  /// **'Back spring secured'**
  String get statusBackSpringSecured;

  /// No description provided for @statusForwardSpringReleased.
  ///
  /// In en, this message translates to:
  /// **'Forward spring released'**
  String get statusForwardSpringReleased;

  /// No description provided for @statusBackSpringReleased.
  ///
  /// In en, this message translates to:
  /// **'Back spring released'**
  String get statusBackSpringReleased;

  /// No description provided for @statusAllLinesSecured.
  ///
  /// In en, this message translates to:
  /// **'All lines secured. Release to depart.'**
  String get statusAllLinesSecured;

  /// No description provided for @statusLevelRestarted.
  ///
  /// In en, this message translates to:
  /// **'Level restarted'**
  String get statusLevelRestarted;

  /// No description provided for @statusMissionAccomplished.
  ///
  /// In en, this message translates to:
  /// **'MISSION ACCOMPLISHED'**
  String get statusMissionAccomplished;

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'FAILED'**
  String get statusFailed;

  /// No description provided for @statusRiverFlow.
  ///
  /// In en, this message translates to:
  /// **'Current: {speed} kn'**
  String statusRiverFlow(String speed);

  /// No description provided for @statusHighSeas.
  ///
  /// In en, this message translates to:
  /// **'Open sea. Hold position.'**
  String get statusHighSeas;

  /// No description provided for @crashNose.
  ///
  /// In en, this message translates to:
  /// **'CRITICAL: Bow collision!'**
  String get crashNose;

  /// No description provided for @crashSide.
  ///
  /// In en, this message translates to:
  /// **'CRASH: Excessive side impact.'**
  String get crashSide;

  /// No description provided for @level1Name.
  ///
  /// In en, this message translates to:
  /// **'First Pier'**
  String get level1Name;

  /// No description provided for @level1Description.
  ///
  /// In en, this message translates to:
  /// **'A quiet marina. Park the yacht in the empty slot between other vessels.'**
  String get level1Description;

  /// No description provided for @level2Name.
  ///
  /// In en, this message translates to:
  /// **'Departure Alongside'**
  String get level2Name;

  /// No description provided for @level2Description.
  ///
  /// In en, this message translates to:
  /// **'Yacht is moored alongside with 4 lines.'**
  String get level2Description;

  /// No description provided for @level3Name.
  ///
  /// In en, this message translates to:
  /// **'Stern-to Mooring'**
  String get level3Name;

  /// No description provided for @level3Description.
  ///
  /// In en, this message translates to:
  /// **'Moor stern-to: stern port, stern starboard, and lazy line to anchor. Side wind.'**
  String get level3Description;

  /// No description provided for @mooringSternPort.
  ///
  /// In en, this message translates to:
  /// **'STERN PORT'**
  String get mooringSternPort;

  /// No description provided for @mooringSternStarboard.
  ///
  /// In en, this message translates to:
  /// **'STERN STARBOARD'**
  String get mooringSternStarboard;

  /// No description provided for @mooringLazyLine.
  ///
  /// In en, this message translates to:
  /// **'MOORING LINE'**
  String get mooringLazyLine;

  /// No description provided for @mooringGiveSternPort.
  ///
  /// In en, this message translates to:
  /// **'Give stern port'**
  String get mooringGiveSternPort;

  /// No description provided for @mooringGiveSternStarboard.
  ///
  /// In en, this message translates to:
  /// **'Give stern starboard'**
  String get mooringGiveSternStarboard;

  /// No description provided for @mooringGiveLazyLine.
  ///
  /// In en, this message translates to:
  /// **'Give mooring line'**
  String get mooringGiveLazyLine;

  /// No description provided for @levelSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Level Settings'**
  String get levelSettingsTitle;

  /// No description provided for @sectionWind.
  ///
  /// In en, this message translates to:
  /// **'WIND'**
  String get sectionWind;

  /// No description provided for @sectionCurrent.
  ///
  /// In en, this message translates to:
  /// **'CURRENT'**
  String get sectionCurrent;

  /// No description provided for @sectionPropeller.
  ///
  /// In en, this message translates to:
  /// **'PROPELLER WALK'**
  String get sectionPropeller;

  /// No description provided for @labelStrength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get labelStrength;

  /// No description provided for @labelDirection.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get labelDirection;

  /// No description provided for @labelSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get labelSpeed;

  /// No description provided for @propellerRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get propellerRight;

  /// No description provided for @propellerLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get propellerLeft;

  /// No description provided for @buttonBack.
  ///
  /// In en, this message translates to:
  /// **'BACK'**
  String get buttonBack;

  /// No description provided for @compassN.
  ///
  /// In en, this message translates to:
  /// **'N'**
  String get compassN;

  /// No description provided for @compassNE.
  ///
  /// In en, this message translates to:
  /// **'NE'**
  String get compassNE;

  /// No description provided for @compassE.
  ///
  /// In en, this message translates to:
  /// **'E'**
  String get compassE;

  /// No description provided for @compassSE.
  ///
  /// In en, this message translates to:
  /// **'SE'**
  String get compassSE;

  /// No description provided for @compassS.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get compassS;

  /// No description provided for @compassSW.
  ///
  /// In en, this message translates to:
  /// **'SW'**
  String get compassSW;

  /// No description provided for @compassW.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get compassW;

  /// No description provided for @compassNW.
  ///
  /// In en, this message translates to:
  /// **'NW'**
  String get compassNW;

  /// No description provided for @level4Name.
  ///
  /// In en, this message translates to:
  /// **'Stern-to with Anchor'**
  String get level4Name;

  /// No description provided for @level4Description.
  ///
  /// In en, this message translates to:
  /// **'Drop anchor in the designated zone, back up to the pier, and secure two stern lines.'**
  String get level4Description;

  /// No description provided for @controlDropAnchor.
  ///
  /// In en, this message translates to:
  /// **'DROP ANCHOR'**
  String get controlDropAnchor;

  /// No description provided for @statusAnchorGetCloser.
  ///
  /// In en, this message translates to:
  /// **'Enter the green zone to drop anchor'**
  String get statusAnchorGetCloser;

  /// No description provided for @statusAnchorDropped.
  ///
  /// In en, this message translates to:
  /// **'Anchor dropped!'**
  String get statusAnchorDropped;

  /// No description provided for @level5Name.
  ///
  /// In en, this message translates to:
  /// **'Baltic Mooring'**
  String get level5Name;

  /// No description provided for @level5Description.
  ///
  /// In en, this message translates to:
  /// **'Moor bow-first between four piles, then secure bow lines to the dock.'**
  String get level5Description;

  /// No description provided for @mooringAftPilePort.
  ///
  /// In en, this message translates to:
  /// **'AFT PORT PILE'**
  String get mooringAftPilePort;

  /// No description provided for @mooringAftPileStarboard.
  ///
  /// In en, this message translates to:
  /// **'AFT STBD PILE'**
  String get mooringAftPileStarboard;

  /// No description provided for @mooringBowPort.
  ///
  /// In en, this message translates to:
  /// **'BOW PORT'**
  String get mooringBowPort;

  /// No description provided for @mooringBowStarboard.
  ///
  /// In en, this message translates to:
  /// **'BOW STARBOARD'**
  String get mooringBowStarboard;

  /// No description provided for @mooringGiveAftPilePort.
  ///
  /// In en, this message translates to:
  /// **'Release aft port pile'**
  String get mooringGiveAftPilePort;

  /// No description provided for @mooringGiveAftPileStarboard.
  ///
  /// In en, this message translates to:
  /// **'Release aft stbd pile'**
  String get mooringGiveAftPileStarboard;

  /// No description provided for @mooringGiveBowPort.
  ///
  /// In en, this message translates to:
  /// **'Release bow port'**
  String get mooringGiveBowPort;

  /// No description provided for @mooringGiveBowStarboard.
  ///
  /// In en, this message translates to:
  /// **'Release bow starboard'**
  String get mooringGiveBowStarboard;

  /// No description provided for @level6Name.
  ///
  /// In en, this message translates to:
  /// **'Narrow Alongside'**
  String get level6Name;

  /// No description provided for @level6Description.
  ///
  /// In en, this message translates to:
  /// **'Navigate a tight channel lined with moored yachts and park alongside.'**
  String get level6Description;

  /// No description provided for @level7Name.
  ///
  /// In en, this message translates to:
  /// **'Narrow Stern-to Mooring'**
  String get level7Name;

  /// No description provided for @level7Description.
  ///
  /// In en, this message translates to:
  /// **'Thread the channel and moor stern-to with a mooring line. Strong side wind.'**
  String get level7Description;

  /// No description provided for @level8Name.
  ///
  /// In en, this message translates to:
  /// **'Narrow Stern-to Anchor'**
  String get level8Name;

  /// No description provided for @level8Description.
  ///
  /// In en, this message translates to:
  /// **'Drop anchor in the channel, then reverse to the pier and secure two stern lines.'**
  String get level8Description;

  /// No description provided for @level9Name.
  ///
  /// In en, this message translates to:
  /// **'Narrow Baltic Mooring'**
  String get level9Name;

  /// No description provided for @level9Description.
  ///
  /// In en, this message translates to:
  /// **'Enter a narrow channel bow-first and secure all four lines to the piles.'**
  String get level9Description;

  /// No description provided for @levelInstructionTitle.
  ///
  /// In en, this message translates to:
  /// **'Level briefing'**
  String get levelInstructionTitle;

  /// No description provided for @levelInstructionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Instructions for this level'**
  String get levelInstructionTooltip;

  /// No description provided for @levelInstruction1.
  ///
  /// In en, this message translates to:
  /// **'• W/S — throttle, A/D — rudder.\n• Move into the green berth between moored yachts and stop with bow and stern near the bollards.\n• When the buttons appear, give bow and stern lines.\n• Win: both lines secured and low speed.'**
  String get levelInstruction1;

  /// No description provided for @levelInstruction2.
  ///
  /// In en, this message translates to:
  /// **'• You start with four lines already made fast.\n• Release bow, stern, and both springs when you are ready to depart.\n• Win: all lines are free and the yacht has left the green zone.'**
  String get levelInstruction2;

  /// No description provided for @levelInstruction3.
  ///
  /// In en, this message translates to:
  /// **'• Stern-to: approach the pier astern; the mooring buoy lies opposite the green zone.\n• Secure stern port and stern starboard, then the lazy line to the buoy.\n• Win: both stern lines and the lazy line secured, correct heading, nearly stopped.'**
  String get levelInstruction3;

  /// No description provided for @levelInstruction4.
  ///
  /// In en, this message translates to:
  /// **'• Enter the green anchor circle and drop anchor when prompted.\n• Back toward the pier and secure two stern lines to the bollards.\n• Win: anchor down, both stern lines fast, correct heading, low speed.'**
  String get levelInstruction4;

  /// No description provided for @levelInstruction5.
  ///
  /// In en, this message translates to:
  /// **'• Bow-first between the four piles. Aft lines to the aft piles; bow lines to the dock bollards.\n• Typical order: aft port and starboard, then bow port and starboard.\n• Win: all four lines, bow perpendicular to the dock, stopped.'**
  String get levelInstruction5;

  /// No description provided for @levelInstruction6.
  ///
  /// In en, this message translates to:
  /// **'• Thread the narrow channel without hitting moored yachts.\n• Park alongside the right finger; the green rectangle is your berth.\n• Win: bow and stern lines secured, low speed.'**
  String get levelInstruction6;

  /// No description provided for @levelInstruction7.
  ///
  /// In en, this message translates to:
  /// **'• Pass the channel, then reverse stern-to to the right finger.\n• Mooring buoy mirrors the green zone; stern lines first, then the lazy line to the buoy.\n• Win: both sterns and lazy line secured, heading and speed in range.'**
  String get levelInstruction7;

  /// No description provided for @levelInstruction8.
  ///
  /// In en, this message translates to:
  /// **'• Drop anchor inside the green ring in the channel, then reverse to the pier.\n• Two stern lines: port to the lower bollard, starboard to the upper (along the finger).\n• Win: anchor down, both sterns fast, correct heading, stopped.'**
  String get levelInstruction8;

  /// No description provided for @levelInstruction9.
  ///
  /// In en, this message translates to:
  /// **'• Bow-first into the slot; four piles sit at the green zone corners — do not ram them.\n• Aft lines to the channel-side piles, bow lines to the pier-side piles.\n• Win: all four lines, bow toward the finger, stopped.'**
  String get levelInstruction9;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
