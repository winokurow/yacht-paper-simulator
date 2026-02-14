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
  /// **'Yacht Paper Simulator'**
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
  /// **'Moored Successfully'**
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
  String briefingTitle(String levelName);

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
  /// **'RIGHT-HAND PROPELLER:'**
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
  /// **'SET SAIL!'**
  String get startJourney;

  /// No description provided for @mooringBow.
  ///
  /// In en, this message translates to:
  /// **'BOW'**
  String get mooringBow;

  /// No description provided for @mooringStern.
  ///
  /// In en, this message translates to:
  /// **'STERN'**
  String get mooringStern;

  /// No description provided for @mooringGiveBow.
  ///
  /// In en, this message translates to:
  /// **'MOOR BOW'**
  String get mooringGiveBow;

  /// No description provided for @mooringGiveStern.
  ///
  /// In en, this message translates to:
  /// **'MOOR STERN'**
  String get mooringGiveStern;

  /// No description provided for @victoryTitle.
  ///
  /// In en, this message translates to:
  /// **'SUCCESSFUL MOORING!'**
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
  /// **'Vessel securely moored.'**
  String get victoryMessageShort;

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
  /// **'SHIP\'S LOG'**
  String get levelSelectionTitle;
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
