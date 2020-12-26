; =*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
;  Author: Florian Muecke
;  Copyright: Florian Muecke, 2005
;  Description: main include file for uneis
; =*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=

include windows.inc
include gdi32.inc
include user32.inc
include kernel32.inc
include Comctl32.inc
include masm32.inc
include ole32.inc
include oleaut32.inc
include advapi32.inc

includelib gdi32.lib
includelib user32.lib
includelib kernel32.lib
includelib Comctl32.lib
includelib masm32.lib
includelib ole32.lib
includelib oleaut32.lib
includelib advapi32.lib

;--------------PROTOTYPES----------
Wizard          PROTO
ConsoleDlg      PROTO	:DWORD,:DWORD,:DWORD,:DWORD

;-----------------MACROS-----------
    m2m MACRO M1, M2
        push M2
        pop  M1
    ENDM

    return MACRO arg
	   mov eax, arg
	   ret
    ENDM

;----------------------------------
.const



IDD_CONSOLE		equ 2000

PSM_SETHEADERSUBTITLE   equ WM_USER+127


.data
caption         DB "Easy (Un)Installation System",0

;include german.inc
include english.inc
Buffer          DB MAX_PATH dup(0)
lpcmdline       DD 0
dummy_dd        DD 0
phkResult		DD 0
KeyUEF          DB "UnEisFile",0
UninstallKey	DB "Software\Microsoft\Windows\CurrentVersion\Uninstall\",MAX_PATH dup(0)
CommandLine     db "setup.bat",0
FontName        DB "Terminal",0
drive_c         DB "c:\",0
lFont           LOGFONT <0>
hInstance       DD 0
hPs             DD 0
hPsDlg		    DD 0
hPropSheet      DD 0
hFont           DD 0
hwndEdit        DD 0
ThreadID        DD 0
hThread         DD 0
