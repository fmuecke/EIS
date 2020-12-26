; =*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
;  Author: Florian Muecke
;  Copyright: Florian Muecke, 2006
;  Description: german language file for EIS
; =*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=


ErrMsg          DB "Fehler",0
ErrDirectory    DB "Das Verzeichnis darf keine der folgenden Zeichen enthalten: ",13,10,13,10,"& % "" ? * < > | : \ /",0
ErrRes          DB "kann Resourcen nicht entpacken",0
ErrDll          DB "kann Entpacker-DLL nicht laden",0
ErrIni          DB "kann Werte aus Initialisierungsdatei nicht lesen",0
ErrEnv          DB "kann Datei für Umgebungsvariablen nicht erstellen",0
ErrArcName      DB "Name des Archives ist zu lang",0
ErrDrive        DB "Auf diesem Laufwerk kann nicht installiert werden. Bitte ein anderes auswählen!",0
RNoMemoryMsg    DB "nicht genug Speicher um Datenstrukturen zu initialisieren",0
RBadDataMsg     DB "Archivkopf beschädigt",0
RBadDataMsg2    DB "CRC Fehler in Datei",0
RBadArchiveMsg  DB "Datei ist kein gültiges RAR Archiv",0
REOpenMsg       DB "kann Archiv nicht öffnen",0
RECloseMsg      DB "kann Archiv nicht schließen",0
RECreateMsg     DB "kann Datei nicht erstellen",0
REReadMsg       DB "kann Daten nicht lesen",0
REWriteMsg      DB "kann Daten nicht schreiben",0
REUnknown       DB "unbekannter Fehler",0
RVolAskMsg      DB "Kann nächstes Archiv nicht finden.",13,10,"Benötige Datenträger mit ",0
RVolAskMsg2     DB 13,10,"Bitte einlegen!",0

MsgAbout        DB "Easy Installation System v1.3.00",13,10,13,10
                DB "Copyleft 2003-2005 Florian Mücke",13,10,13,10
                DB "Homepage: http://beam.to/install",13,10
                DB "(Kommantare, Fehler, Probleme etc bitte dort melden)",13,10,13,10
                DB "Speziellen Dank an:",13,10,"Iczelion, Hutch, KetilO, Test Department, Ernest Murphy, Eugene Roshal, B.Ziegler, A.Ochotta",0
MsgExit         DB "Der Setup-Vorgang ist noch nicht abgeschlossen.",13,10,"Wirklich beenden?",0
MsgLicense      DB "Haben Sie die Lizenz-Informationen durchgelesen und akzeptieren diese?",0
nfoTitle        DB "Programm-Informationen",0
nfoSTitle       DB "Lesen Sie bitte die Informationen durch, es könnten Ihnen",13,10,"sonst besondere Programmhinweise entgehen.",0
SettingsTitle   DB "Einstellungen zur Installation",0
SettingsSTitle  DB "Hier können Sie entscheiden, ob Verknüpfungen angelegt,",13,10,"und in welches Verzeichnis installiert werden soll.",0
ExtractTitle    DB "Entpacke Daten",0
ExtractSTitle   DB "Lehnen Sie sich zurück während die Daten extrahiert werden...",0
ConsoleTitle    DB "Anwendung einrichten",0
ConsoleTitle2   DB "Setup - abgeschlossen",0
ConsoleSTitle   DB "Die Anwendung wird auf Ihrem System eingerichtet...",0
ConsoleSTitle2  DB "Die Installation ist abgeschlossen.",13,10,"Sie können das Programm jetzt mit ""Fertig stellen"" verlassen.",0
AboutStr        DB "Über EIS...",0


;browse dialog
DlgItemTxt5500  DB "Verzeichnis auswählen",0
DlgItemTxt2     DB "Abbrechen",0
DlgItemTxt5505  DB "Neues Verzeichnis für die Anwendung:",0
DlgItemTxt5504  DB "Aktuelles Verzeichnis:",0

;console dialog
DlgItemTxt2000  DB "Setup - Einrichten",0

;extract dialog
DlgItemTxt3000  DB "Setup - entpacke Daten",0
DlgItemTxt3010  DB "Quelle:",0
DlgItemTxt3008  DB "Ziel:",0
DlgItemTxt3006  DB "Aktuelle Datei",0
DlgItemTxt3003  DB "Gesamtfortschritt",0
DlgItemTxt3012  DB "Aktuelles Archiv:",0

;nfo dialog
DlgItemTxt1000  DB "Setup - Programm Informationen",0

;settings dialog
DlgItemTxt5000  DB "Setup - Installationseinstellungen",0
DlgItemTxt5007  DB "Durchsuchen",0
DlgItemTxt5014  DB "Wo sollen Shortcuts angelegt werden?",0
DlgItemTxt5013  DB "Verknüpfungen",0
DlgItemTxt5002  DB "im Startmenü",0
DlgItemTxt5003  DB "auf dem Desktop",0
DlgItemTxt5008  DB "Platz benötigt:",0
DlgItemTxt5009  DB "Platz vorhanden:",0
DlgItemTxt5010  DB "Zielverzeichnis",0
DlgItemTxt5011  DB "Klicken Sie Weiter um mit den gewählten Einstellungen fortzufahren oder Abbrechen um die Anwendung zu schließen.",0
DlgItemTxt5012  DB "Um ein anderes als das gewählte Zielverzeichnis auszuwählen klicken Sie bitte den Durchsuchen Knopf. Beachten Sie, dass genügend Platz frei sein muss.",0

;welcome dialog
DlgItemTxt4000  DB "Setup - Willkommen",0
DlgItemTxt4003  DB "Der Setup-Asisstent wird Sie nun durch den weiteren Installationsverlauf führen.",0
DlgItemTxt4004  DB "Bitte nehmen Sie sich die Zeit und lesen die Informationen des Herstellers auf der nächsten Seite. Ihnen könnten sonst wichtige Hinweise zum Programm entgehen.",0

;---------------------------------------------------------------------------
;end of german.inc