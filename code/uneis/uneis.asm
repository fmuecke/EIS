; =*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
;
;  Version: 1.3.00, 12.09.05
;
;  Created: 05.10.2003
;
;  Author: Florian Muecke
;
;  Copyright: Florian Muecke, 2005
;
;  Description: uninstall program for EIS - Easy Installation System
;
; =*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=


.586
.model flat,stdcall  ;32 bit memory model
option casemap :none  ;case sensitive

include uneis.inc

.code

start:

    invoke SetCurrentDirectory,addr drive_c
	invoke GetModuleHandle,NULL
	mov    hInstance,eax
	invoke InitCommonControls
    invoke GetCommandLine
    mov lpcmdline,eax
    invoke lstrlen,lpcmdline
    sub eax,3       ;surrounding "" + 1 space (somehow the separating space counts...)
    push eax
    invoke GetModuleFileName,0,addr Buffer,MAX_PATH
    mov ebx,eax     ;save result to ebx
    pop eax         ;get stored value
    .if eax==ebx    ;==>no cmdline args specified
        invoke MessageBox,0,addr ErrMsg,addr caption,MB_ICONSTOP
        jmp exit
    .endif

    mov al,byte ptr [Buffer] ;check if module file name is quotated
    .if al == '"'
        add ebx,2
    .endif
    inc ebx             ;space before first arg
    add lpcmdline,ebx ;move commandline ptr to first arg
	invoke lstrcpy,addr Buffer,addr ask
	invoke lstrcat,addr Buffer,lpcmdline
	invoke lstrcat,addr Buffer,addr ask2
	invoke MessageBox,0,addr Buffer,addr caption,MB_YESNO or MB_ICONQUESTION
    .if eax==IDYES
        invoke lstrcat,addr UninstallKey,lpcmdline
        invoke RegOpenKeyEx,HKEY_LOCAL_MACHINE,addr UninstallKey,0,KEY_READ,addr phkResult
        .if eax!=ERROR_SUCCESS
            invoke MessageBox,0,addr err1,addr caption,MB_ICONSTOP
            jmp exit
        .endif
        mov dummy_dd,MAX_PATH
        invoke RegQueryValueEx,phkResult,addr KeyUEF,0,0,addr Buffer,addr dummy_dd
        .if eax!=ERROR_SUCCESS
            invoke MessageBox,0,addr err1,addr caption,MB_ICONSTOP
           	invoke RegCloseKey,phkResult
            jmp exit
        .endif
    	invoke RegCloseKey,phkResult
    	invoke Wizard
    .endif

exit:	

	invoke ExitProcess,0

;########################################################################

Wizard proc
	LOCAL	PropSheet:PROPSHEETPAGE
	LOCAL	PropHdr:PROPSHEETHEADER


	;Set up the 1st property sheet (WELCOME)
	mov		PropSheet.dwSize,sizeof PROPSHEETPAGE
	m2m		PropSheet.dwFlags,PSP_DEFAULT or PSP_USEHEADERSUBTITLE or PSP_USEHEADERTITLE or PSP_USETITLE
    m2m     PropSheet.pszHeaderTitle,offset ConsoleTitle
    m2m     PropSheet.pszHeaderSubTitle,offset ConsoleSTitle
	m2m		PropSheet.hInstance,hInstance
	m2m		PropSheet.pszTemplate,IDD_CONSOLE
	m2m		PropSheet.pfnDlgProc,offset ConsoleDlg
	m2m		PropSheet.pszTitle,offset caption
	mov		PropSheet.lParam,0
	mov		PropSheet.pfnCallback,0

	; Create the 1 Page
	invoke CreatePropertySheetPage,addr PropSheet
	mov		hPs,eax

	; Set up the property sheet header
	mov		PropHdr.dwSize,sizeof PropHdr
	mov		PropHdr.dwFlags,PSH_WIZARD97 or PSH_HEADER or PSH_WATERMARK
	m2m		PropHdr.hwndParent,NULL
	m2m		PropHdr.hInstance,hInstance
	mov		PropHdr.nPages,1
	mov		PropHdr.nStartPage,0
	m2m		PropHdr.phpage,offset hPs
;---------------------
    mov     PropHdr.pszbmWatermark,111
    mov     PropHdr.pszbmHeader,112
;---------------------

    invoke CreatePropertySheetPage,addr PropSheet

	; Display the property sheet control
	invoke PropertySheet,addr PropHdr
	ret

Wizard endp

ConsoleDlg proc hWin:HWND,uMsg:DWORD,wParam:WPARAM,lParam:LPARAM

      LOCAL Wwd  :DWORD
      LOCAL Wht  :DWORD
      LOCAL Wtx  :DWORD
      LOCAL Wty  :DWORD
      LOCAL rect :RECT
      LOCAL hParent:HANDLE
;      LOCAL hMenu:HANDLE
;      LOCAL msg:MSG
      
;    invoke GetParent,hWin
;    mov dummy_dd,eax
;    invoke PeekMessage,addr msg,eax,WM_SYSCOMMAND,WM_SYSCOMMAND,PM_REMOVE
;    .if msg.message == WM_SYSCOMMAND
;        .if msg.wParam==333
;            invoke PeekMessage,addr msg,eax,WM_SYSCOMMAND,WM_SYSCOMMAND,PM_REMOVE
;            invoke MessageBox,hWin,addr MsgAbout,addr caption,MB_OK
;        .else
;            invoke GetParent,hWin
;            invoke PostMessage,eax,WM_SYSCOMMAND,msg.wParam,msg.lParam
;        .endif
;    .endif
;;todo: about message


    mov	eax,uMsg  

	.if eax==WM_COMMAND
		mov eax,wParam
		and	eax,0FFFFh  ;get loword of wParam

    .elseif eax==WM_INITDIALOG
        m2m		hPsDlg[0],hWin
       ; center window
        invoke GetParent,hWin
        mov hParent,eax
        invoke GetWindowRect,hParent,addr rect
        mov eax,rect.right
        sub eax,rect.left
        mov Wwd,eax
        invoke GetSystemMetrics,SM_CXSCREEN
        sub eax,Wwd
        shr eax,1
        mov Wtx,eax
        mov eax,rect.bottom
        sub eax,rect.top
        mov Wht,eax
        invoke GetSystemMetrics,SM_CYSCREEN
        sub eax,Wht
        shr eax,1
        mov Wty,eax
        invoke SetWindowPos,hParent,HWND_TOP,Wtx,Wty,Wwd,Wht,SWP_SHOWWINDOW

       ; load icon
        invoke LoadIcon,hInstance,104
        invoke SendMessage,hParent,WM_SETICON,1,eax

       ; set sys menu item (about-box)
;        invoke GetSystemMenu,hParent,0
;        mov hMenu,eax          ;;todo: closehandle!
;        invoke AppendMenu,hMenu,MF_SEPARATOR,0,0
;        invoke AppendMenu,hMenu,MF_STRING,333,addr AboutStr

        ;load font
        invoke lstrcpy,addr lFont.lfFaceName,addr FontName
        mov lFont.lfHeight,9
        mov lFont.lfWeight,FW_REGULAR
    	mov lFont.lfCharSet,OEM_CHARSET
    	invoke CreateFontIndirect,addr lFont
        mov hFont,eax

        invoke GetDlgItem,hWin,2001 ;get EditBox handle
        mov hwndEdit,eax     
			
        invoke SendDlgItemMessage,hWin,2001,WM_SETFONT,hFont,TRUE
			
        ;redirect thread proc
        mov edx,OFFSET ConsoleThread
        invoke CreateThread,0,0,edx,NULL,NORMAL_PRIORITY_CLASS,addr ThreadID
        mov hThread,eax  
        ;;todo: thread handle schliessen


   	.elseif uMsg==WM_CTLCOLORSTATIC
      	invoke SetTextColor,wParam,Green
    	invoke SetBkColor,wParam,Black
		invoke GetStockObject,BLACK_BRUSH    	
		ret


	.elseif	eax==WM_NOTIFY
		mov	edx,lParam
		mov	eax,NMHDR.code[edx]

		.if eax==PSN_SETACTIVE
			;page gaining focus
			m2m    hPropSheet,NMHDR.hwndFrom[edx]
			invoke PostMessage,hPropSheet,PSM_SETWIZBUTTONS,0,PSWIZB_DISABLEDFINISH
			invoke SetWindowLong,hWin,DWL_MSGRESULT,0

        .elseif eax==PSN_WIZFINISH
            ;clean up
			invoke CloseHandle,hThread
            invoke DeleteObject,hFont ;free nfo font
	
		.elseif eax==PSN_KILLACTIVE
			;page loosing focus
			invoke SetWindowLong,hWin,DWL_MSGRESULT,0

		.elseif eax==PSN_RESET
			;Add own cancel code here

		.endif

    .elseif eax==WM_DESTROY   
        ;clean up
        invoke CloseHandle,hThread
        invoke DeleteObject,hFont ;free nfo font

	.else
		return FALSE
	.endif
	return TRUE

ConsoleDlg endp

ConsoleThread PROC 
    LOCAL hRead:DWORD
    LOCAL hWrite:DWORD
    LOCAL sat:SECURITY_ATTRIBUTES
    LOCAL startupinfo:STARTUPINFO
	LOCAL pinfo:PROCESS_INFORMATION
	LOCAL buffer[1024]:byte
	LOCAL bytesRead:DWORD

        ;;todo: 2-way console-box

        mov sat.nLength,sizeof SECURITY_ATTRIBUTES
        mov sat.lpSecurityDescriptor,NULL
        mov sat.bInheritHandle,TRUE

        invoke CreatePipe,addr hRead,addr hWrite,addr sat,0
        
        .if eax==NULL
            invoke MessageBox,0,addr ErrMsg,addr caption,MB_ICONERROR or MB_OK ;;todo: PARENT,Fehlermeldung
        .else
            mov startupinfo.cb,sizeof STARTUPINFO
            invoke GetStartupInfo,addr startupinfo
            mov eax,hWrite
            mov startupinfo.hStdOutput,eax
            mov startupinfo.hStdError,eax
            mov startupinfo.dwFlags,STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES
            mov startupinfo.wShowWindow,SW_HIDE
           ;create process
            invoke CreateProcess,NULL,addr Buffer,NULL,NULL,TRUE,NULL,NULL,NULL,addr startupinfo,addr pinfo
            .if eax==NULL
                invoke MessageBox,0,addr ErrMsg,addr caption,MB_ICONERROR or MB_OK ;;todo: PARENT,Fehlermeldung
            .else
                invoke CloseHandle,hWrite
                .while TRUE
                    invoke RtlZeroMemory,addr buffer,1024
                    invoke ReadFile,hRead,addr buffer,1023,addr bytesRead,NULL
                    .if eax==NULL
                        .break
                    .else
                        invoke SendMessage,hwndEdit,EM_SETSEL,-1,0
                        invoke SendMessage,hwndEdit,EM_REPLACESEL,FALSE,addr buffer
                    .endif
				.endw
			.endif
            invoke CloseHandle,hRead
        .endif
        invoke DeleteFile,addr Buffer
        invoke PostMessage,hPropSheet,PSM_SETWIZBUTTONS,0,PSWIZB_FINISH;enable finish button
    	invoke PostMessage,hPropSheet,PSM_CANCELTOCLOSE,0,0 ;disable cancel button
    	invoke PostMessage,hPropSheet,PSM_SETHEADERSUBTITLE,0,addr ConsoleSTitle2
    	invoke PostMessage,hPropSheet,PSM_SETTITLE,0,addr ConsoleTitle2
    	invoke SetWindowLong,hPropSheet,DWL_MSGRESULT,1 ;set TRUE
    ret
ConsoleThread endp

end start
