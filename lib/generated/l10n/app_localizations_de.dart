// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get gameTitle => 'Yacht-Papier-Simulator';

  @override
  String get menuStartGame => 'Spiel starten';

  @override
  String get menuSettings => 'Einstellungen';

  @override
  String get menuLevels => 'Level';

  @override
  String get menuQuit => 'Beenden';

  @override
  String get controlThrottle => 'Schub';

  @override
  String get controlSteering => 'Steuerung';

  @override
  String get controlWind => 'Wind';

  @override
  String get stateVictory => 'Sieg!';

  @override
  String get stateGameOver => 'Spiel vorbei';

  @override
  String get stateMooredSuccessfully => 'Erfolgreich vertäut';

  @override
  String get settingsSelectLanguage => 'Sprache wählen';

  @override
  String get settingsSound => 'Ton';

  @override
  String get settingsMusic => 'Musik';

  @override
  String briefingTitle(String levelName) {
    return 'BRIEFING: $levelName';
  }

  @override
  String get briefingSessionSettings => 'SITZUNGSEINSTELLUNGEN';

  @override
  String get windStrength => 'WINDSTÄRKE:';

  @override
  String get propellerRightHanded => 'RECHTSGÄNGIGER PROPELLER:';

  @override
  String get yes => 'JA';

  @override
  String get no => 'NEIN';

  @override
  String get cancel => 'ABBRECHEN';

  @override
  String get startJourney => 'IN SEE!';

  @override
  String get mooringBow => 'BUG';

  @override
  String get mooringStern => 'HECK';

  @override
  String get mooringGiveBow => 'BUG VERTÄUEN';

  @override
  String get mooringGiveStern => 'HECK VERTÄUEN';

  @override
  String get victoryTitle => 'ERFOLGREICH VERTÄUT!';

  @override
  String get victoryMessage => 'Sie haben das Schiff perfekt gesichert.';

  @override
  String get victoryPlayAgain => 'NOCHMAL SPIELEN';

  @override
  String get victoryNextLevel => 'NÄCHSTES LEVEL';

  @override
  String get victoryMessageShort => 'Schiff sicher im Hafen.';

  @override
  String get gameOverTitle => 'VORFALL';

  @override
  String get gameOverRetry => 'WIEDERHOLEN';

  @override
  String get gameOverMainMenu => 'HAUPTMENÜ';

  @override
  String get levelSelectionTitle => 'SCHIFFSLOGbuch';
}
