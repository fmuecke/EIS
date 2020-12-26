; =*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
;  Author: Florian Muecke
;  Copyright: Florian Muecke, 2006
;  Description: english language file for EIS
; =*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=

;english.inc - english language include file

ErrMsg          DB "error",0
ErrDirectory    DB "The folder mustn't contain any of these characters: ",13,10,13,10,"& % "" ? * < > | : \ /",0
ErrRes          DB "unable to extract file resources",0
ErrDll          DB "unable to load unpacker dll",0
ErrIni          DB "unable to read ini file settings",0
ErrEnv          DB "unable to create file for environment settings",0
ErrArcName      DB "archive name to long",0
ErrDrive        DB "You can not install on that drive - please choose another one!",0
RNoMemoryMsg    DB "not enough memory to init data structures",0
RBadDataMsg     DB "archive header damaged",0
RBadDataMsg2    DB "file crc error",0
RBadArchiveMsg  DB "file is no valid RAR archive",0
REOpenMsg       DB "unable to open archive",0
RECloseMsg      DB "unable to close archive",0
RECreateMsg     DB "unable to create file",0
REReadMsg       DB "unable to read file",0
REWriteMsg      DB "unable to write file",0
REUnknown       DB "unkown error",0
RVolAskMsg      DB "Unable to find next volume. Media with ",0
RVolAskMsg2     DB "needed.",13,10,"Please change media and continue.",0

MsgAbout        DB "Easy Installation System v1.3.00",13,10,13,10
                DB "Copyleft 2003-2005 Florian Mücke",13,10,13,10
                DB "Homepage: http://beam.to/install",13,10
                DB "(report comments, problem reports there)",13,10,13,10
                DB "Special greetings to:",13,10,"Iczelion, Hutch, KetilO, Test Department, Ernest Murphy, Eugene Roshal, B.Ziegler, A.Ochotta",0
MsgExit         DB "The setup process is not complete.",13,10,"Really abort?",0
MsgLicense      DB "Have you read the license information and do you aggree?",0
nfoTitle        DB "Program information",0
nfoSTitle       DB "Please read the provided information.",13,10,"You could miss important notes on the program.",0
SettingsTitle   DB "Installation settings",0
SettingsSTitle  DB "Here you can decide which shortcuts should be created,",13,10,"and specify the installation directory.",0
ExtractTitle    DB "Extracting files",0
ExtractSTitle   DB "Lean back! EIS extracts files...",0
ConsoleTitle    DB "Application setup",0
ConsoleTitle2   DB "Setup - finished",0
ConsoleSTitle   DB "The application is being configured for your system...",0
ConsoleSTitle2  DB "The installation process is complete.",13,10,"You can leave the program now with the ""Finish"" button.",0
AboutStr        DB "About EIS...",0


;browse dialog
DlgItemTxt5500  DB "Choose directory",0
DlgItemTxt2     DB "Cancel",0
DlgItemTxt5505  DB "New directory for application:",0
DlgItemTxt5504  DB "Current directory:",0

;console dialog
DlgItemTxt2000  DB "Setup - Configuration",0

;extract dialog
DlgItemTxt3000  DB "Setup - Extracting files",0
DlgItemTxt3010  DB "Source:",0
DlgItemTxt3008  DB "Destination:",0
DlgItemTxt3006  DB "Current file",0
DlgItemTxt3003  DB "Overall process",0
DlgItemTxt3012  DB "Current volume:",0

;nfo dialog
DlgItemTxt1000  DB "Setup - Program information",0

;settings dialog
DlgItemTxt5000  DB "Setup - Installation settings",0
DlgItemTxt5007  DB "Browse",0
DlgItemTxt5014  DB "Where should the shortcuts be created?",0
DlgItemTxt5013  DB "Shortcuts",0
DlgItemTxt5002  DB "Start menu",0
DlgItemTxt5003  DB "Desktop",0
DlgItemTxt5008  DB "Space required:",0
DlgItemTxt5009  DB "Space available:",0
DlgItemTxt5010  DB "Destination directory",0
DlgItemTxt5011  DB "Click ""next"" to continue with the current settings or click ""cancel"" to close installation application.",0
DlgItemTxt5012  DB "To choose an other destination directory click the ""browse"" button. Keep in mind that there has to be enoug free space.",0

;welcome dialog
DlgItemTxt4000  DB "Setup - Welcome",0
DlgItemTxt4003  DB "The setup wizard will guide you through the further installation process.",0
DlgItemTxt4004  DB "Please take the time to read the producer's application information on the following page. Otherwise you could miss some important notes.",0


;---------------------------------------------------------------------------
;end of english.inc