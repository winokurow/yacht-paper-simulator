// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get gameTitle => 'Yacht-Simulator';

  @override
  String get menuStartGame => 'Spiel starten';

  @override
  String get menuSettings => 'Einstellungen';

  @override
  String get menuLevels => 'Level';

  @override
  String get menuQuit => 'Beenden';

  @override
  String get controlThrottle => 'Gas';

  @override
  String get controlSteering => 'Ruder';

  @override
  String get controlWind => 'Wind';

  @override
  String get stateVictory => 'Sieg!';

  @override
  String get stateGameOver => 'Spiel vorbei';

  @override
  String get stateMooredSuccessfully => 'Erfolgreich angelegt';

  @override
  String get settingsSelectLanguage => 'Sprache wählen';

  @override
  String get settingsSound => 'Ton';

  @override
  String get settingsMusic => 'Musik';

  @override
  String briefingTitle(Object levelName) {
    return 'BRIEFING: $levelName';
  }

  @override
  String get briefingSessionSettings => 'SITZUNGS-EINSTELLUNGEN';

  @override
  String get windStrength => 'WINDSTÄRKE:';

  @override
  String get propellerRightHanded => 'RECHTSDREHENDER PROPELLER:';

  @override
  String get yes => 'JA';

  @override
  String get no => 'NEIN';

  @override
  String get cancel => 'ABBRECHEN';

  @override
  String get startJourney => 'LOS GEHT\'S!';

  @override
  String get mooringBow => 'BUGLEINE';

  @override
  String get mooringStern => 'HECKLEINE';

  @override
  String get mooringGiveBow => 'BUGLEINE AUSGEBEN';

  @override
  String get mooringGiveStern => 'HECKLEINE AUSGEBEN';

  @override
  String get mooringForwardSpring => 'Vorderspring';

  @override
  String get mooringBackSpring => 'Achterpring';

  @override
  String get mooringGiveForwardSpring => 'Vorderspring ausgeben';

  @override
  String get mooringGiveBackSpring => 'Achterpring ausgeben';

  @override
  String get victoryTitle => 'ERFOLGREICH ANGELEGT!';

  @override
  String get victoryMessage => 'Sie haben das Schiff perfekt gesichert.';

  @override
  String get victoryPlayAgain => 'WIEDERHOLEN';

  @override
  String get victoryNextLevel => 'NÄCHSTES LEVEL';

  @override
  String get victoryMessageShort =>
      'Das Schiff ist sicher im Hafen festgemacht.';

  @override
  String get victoryTitleDeparted => 'ERFOLGREICH ABGELEGT!';

  @override
  String get victoryMessageShortDeparted =>
      'Sie haben die Liegezone verlassen.';

  @override
  String get gameOverTitle => 'KOLLISION';

  @override
  String get gameOverRetry => 'WIEDERHOLEN';

  @override
  String get gameOverMainMenu => 'HAUPTMENÜ';

  @override
  String get levelSelectionTitle => 'LOGBUCH';

  @override
  String get statusWaiting => 'Warten auf Befehle...';

  @override
  String get statusBowSecured => 'Bugleine fest';

  @override
  String get statusSternSecured => 'Heckleine fest';

  @override
  String get statusBowReleased => 'Bugleine los';

  @override
  String get statusSternReleased => 'Heckleine los';

  @override
  String get statusForwardSpringSecured => 'Vorderspring fest';

  @override
  String get statusBackSpringSecured => 'Achterpring fest';

  @override
  String get statusForwardSpringReleased => 'Vorderspring los';

  @override
  String get statusBackSpringReleased => 'Achterpring los';

  @override
  String get statusAllLinesSecured =>
      'Alle Leinen fest. Loswerfen zum Ablegen.';

  @override
  String get statusLevelRestarted => 'Level neu gestartet';

  @override
  String get statusMissionAccomplished => 'MISSION ERFÜLLT';

  @override
  String get statusFailed => 'FEHLGESCHLAGEN';

  @override
  String statusRiverFlow(String speed) {
    return 'Strömung: $speed kn';
  }

  @override
  String get statusHighSeas => 'Offene See. Position halten.';

  @override
  String get crashNose => 'KRITISCH: Bug-Kollision!';

  @override
  String get crashSide => 'UNFALL: Zu harter Aufprall an der Seite.';

  @override
  String get level1Name => 'Erster Anleger';

  @override
  String get level1Description =>
      'Ruhige Marina. Parken Sie die Yacht in der freien Lücke zwischen anderen Schiffen.';

  @override
  String get level2Name => 'Ablegen längsseits';

  @override
  String get level2Description => 'Yacht liegt mit 4 Leinen längsseits.';

  @override
  String get levelSettingsTitle => 'Level-Einstellungen';

  @override
  String get sectionWind => 'WIND';

  @override
  String get sectionCurrent => 'STRÖMUNG';

  @override
  String get sectionPropeller => 'RADEFFEKT';

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
