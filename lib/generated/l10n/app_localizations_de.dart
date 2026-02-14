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

  @override
  String get statusWaiting => 'Warte auf Befehl...';

  @override
  String get statusBowSecured => 'Bugleine befestigt';

  @override
  String get statusSternSecured => 'Heckleine befestigt';

  @override
  String get statusLevelRestarted => 'Level neu gestartet';

  @override
  String get statusMissionAccomplished => 'MISSION ERFÜLLT';

  @override
  String get statusFailed => 'GESCHEITERT';

  @override
  String statusRiverFlow(String speed) {
    return 'Flussströmung: $speed kn';
  }

  @override
  String get statusHighSeas => 'Hohe See. Position halten.';

  @override
  String get crashNose => 'KRITISCH: Bugkollision!';

  @override
  String get crashSide => 'UNFALL: Zu starke Seitenberührung.';

  @override
  String get level1Name => 'Erste Liegestelle';

  @override
  String get level1Description =>
      'Ruhiger Hafen. Parken Sie die Yacht in der freien Lücke zwischen anderen Booten.';

  @override
  String get level2Name => 'Seine-Strömung';

  @override
  String get level2Description =>
      'Anspruchsvolles Anlegen am Fluss mit starker Querströmung.';

  @override
  String get levelSettingsTitle => 'Level-Einstellungen';

  @override
  String get sectionWind => 'WIND';

  @override
  String get sectionCurrent => 'STRÖMUNG';

  @override
  String get sectionPropeller => 'PROPELLER';

  @override
  String get labelStrength => 'Stärke';

  @override
  String get labelDirection => 'Richtung';

  @override
  String get labelSpeed => 'Geschwindigkeit';

  @override
  String get propellerRight => 'Rechts';

  @override
  String get propellerLeft => 'Links';

  @override
  String get buttonBack => 'ZURÜCK';

  @override
  String get compassN => 'N';

  @override
  String get compassNE => 'NO';

  @override
  String get compassE => 'O';

  @override
  String get compassSE => 'SO';

  @override
  String get compassS => 'S';

  @override
  String get compassSW => 'SW';

  @override
  String get compassW => 'W';

  @override
  String get compassNW => 'NW';
}
