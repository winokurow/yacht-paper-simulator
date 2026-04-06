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
  String get statusMooringGetCloser => 'Näher an die Mooringboje heranfahren';

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
  String get level3Name => 'Heck-an-Mooring';

  @override
  String get level3Description =>
      'Heck-an: Backbord-Achterleine, Steuerbord-Achterleine und Mooring-Leine zum Anker. Seitenwind.';

  @override
  String get mooringSternPort => 'HECK BACKBORD';

  @override
  String get mooringSternStarboard => 'HECK STEUERBORD';

  @override
  String get mooringLazyLine => 'MOORING-LEINE';

  @override
  String get mooringGiveSternPort => 'Heck Backbord los';

  @override
  String get mooringGiveSternStarboard => 'Heck Steuerbord los';

  @override
  String get mooringGiveLazyLine => 'Mooring-Leine los';

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

  @override
  String get level4Name => 'Heck-an mit Anker';

  @override
  String get level4Description =>
      'Anker in der markierten Zone werfen, rückwärts zum Steg fahren und zwei Heckleinen festmachen.';

  @override
  String get controlDropAnchor => 'ANKER WERFEN';

  @override
  String get statusAnchorGetCloser =>
      'In die grüne Zone fahren, um den Anker zu werfen';

  @override
  String get statusAnchorDropped => 'Anker geworfen!';

  @override
  String get level5Name => 'Ostsee-Anlegen';

  @override
  String get level5Description =>
      'Bug voraus zwischen vier Dalben einfahren und Bugleinen am Steg festmachen.';

  @override
  String get mooringAftPilePort => 'HECK BB DALBEN';

  @override
  String get mooringAftPileStarboard => 'HECK STB DALBEN';

  @override
  String get mooringBowPort => 'BUG BACKBORD';

  @override
  String get mooringBowStarboard => 'BUG STEUERBORD';

  @override
  String get mooringGiveAftPilePort => 'Heck Bb Dalben los';

  @override
  String get mooringGiveAftPileStarboard => 'Heck Stb Dalben los';

  @override
  String get mooringGiveBowPort => 'Bug Backbord los';

  @override
  String get mooringGiveBowStarboard => 'Bug Steuerbord los';

  @override
  String get level6Name => 'Enge Marina — Längsseits';

  @override
  String get level6Description =>
      'Navigieren Sie durch einen engen Kanal und legen Sie längsseits an.';

  @override
  String get level7Name => 'Enge Marina — Heck-an mit Mooring';

  @override
  String get level7Description =>
      'Durchfahren Sie den Kanal und legen Sie Heck-an mit Mooring-Leine an. Starker Seitenwind.';

  @override
  String get level8Name => 'Enge Marina — Heck-an mit Anker';

  @override
  String get level8Description =>
      'Anker im Kanal werfen, rückwärts zum Steg und zwei Heckleinen festmachen.';

  @override
  String get level9Name => 'Enge Marina — Ostsee-Anlegen';

  @override
  String get level9Description =>
      'Bug voraus in den engen Kanal einfahren und alle vier Leinen an Dalben festmachen.';

  @override
  String get levelInstructionTitle => 'Level-Briefing';

  @override
  String get levelInstructionTooltip => 'Anleitung zu diesem Level';

  @override
  String get levelInstruction1 =>
      '• W/S — Gas, A/D — Ruder.\n• In die grüne Liegeplatz-Markierung zwischen den Yachten fahren und mit Bug und Heck an den Pollern stoppen.\n• Wenn die Tasten erscheinen, Bug- und Heckleinen geben.\n• Sieg: beide Leinen fest, geringe Fahrt.';

  @override
  String get levelInstruction2 =>
      '• Start mit vier bereits festen Leinen.\n• Bug, Heck und beide Springer loswerfen, wenn Sie ablegen wollen.\n• Sieg: alle Leinen frei und die Yacht hat die grüne Zone verlassen.';

  @override
  String get levelInstruction3 =>
      '• Heck-an: die Mooring-Boje liegt gegenüber der grünen Zone.\n• Heck Backbord und Steuerbord festmachen, dann die Lazy Line zur Boje.\n• Sieg: beide Heckleinen und Mooring, richtiger Kurs, fast Stillstand.';

  @override
  String get levelInstruction4 =>
      '• In den grünen Ankerkreis fahren und Anker werfen, wenn die Taste aktiv ist.\n• Rückwärts zum Steg und zwei Heckleinen an die Pollern.\n• Sieg: Anker aus, beide Heckleinen, Kurs, geringe Fahrt.';

  @override
  String get levelInstruction5 =>
      '• Bug voraus zwischen vier Dalben; Heck an die hinteren Dalben, Bug an die Steg-Pollern.\n• Üblich: zuerst Heck, dann Bug.\n• Sieg: vier Leinen, Bug rechtwinklig zum Steg, Stillstand.';

  @override
  String get levelInstruction6 =>
      '• Durch den engen Kanal ohne Kollision mit liegenden Yachten.\n• Längsseits am rechten Steg; das grüne Rechteck ist die Liege.\n• Sieg: Bug- und Heckleine fest, geringe Fahrt.';

  @override
  String get levelInstruction7 =>
      '• Kanal durchfahren, dann Heck-an zum rechten Steg.\n• Mooring-Boje spiegelt die grüne Zone; zuerst Heckleinen, dann Lazy Line.\n• Sieg: beide Heckleinen und Mooring, Kurs und Fahrt im Rahmen.';

  @override
  String get levelInstruction8 =>
      '• Anker im grünen Ring im Kanal werfen, dann rückwärts zum Steg.\n• Zwei Heckleinen: Backbord zum unteren Poller, Steuerbord zum oberen entlang des Fingers.\n• Sieg: Anker, beide Heckleinen, Kurs, Stillstand.';

  @override
  String get levelInstruction9 =>
      '• Bug voraus in die Box; vier Dalben an den Ecken der grünen Zone — nicht anfahren.\n• Heck an die kanalseitigen Dalben, Bug an die stegsseitigen.\n• Sieg: vier Leinen, Bug zum Finger, Stillstand.';
}
