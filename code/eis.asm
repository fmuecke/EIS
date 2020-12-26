; =*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
;  Version: 1.3.01, 16.03.06
;
;  Created: 05.10.2003
;  Author: Florian Muecke
;  Copyright: Florian Muecke, 2005
;
;  Description: Easy Installation System
; =*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=


.586
.model flat,stdcall  ;32 bit memory model
option casemap :none  ;case sensitive

include eis.inc

;---------------------------------------------------
.code

start:

	invoke GetModuleHandle,NULL
	mov    hInstance,eax
	invoke InitCommonControls

  ;retrieve pseudo random number for tmp dir
    invoke GetTickCount
    invoke wsprintf,addr strBuffer,addr tmpStr,eax
    invoke GetTempPath,255,addr tmpDir
    invoke lstrcat,addr tmpDir,addr strBuffer

  ;create temporary directory
    invoke CreateDirectory,addr tmpDir,0
    .if eax == 0
      invoke MessageBox,0,addr ErrRes,addr caption,MB_ICONSTOP
      jmp exit
    .endif

  ;load .nfo file
    invoke LoadResFile,addr resName3,603,addr tmpDir
    .if eax == 0
      invoke MessageBox,0,addr ErrRes,addr caption,MB_ICONSTOP
      jmp exit
    .endif
    mov nfoAddress,eax
    mov nfoSize,ebx

  ;load unrar.dll    
    invoke LoadResFile,addr resName1,601,addr tmpDir
    .if eax == 0
      invoke MessageBox,0,addr ErrRes,addr caption,MB_ICONSTOP
      jmp exit
    .endif

  ;load eis.ini
    invoke LoadResFile,addr resName2,602,addr tmpDir
    .if eax == 0
      invoke MessageBox,0,addr ErrRes,addr caption,MB_ICONSTOP
      jmp exit
    .endif

  ;initialize unrar.dll
    invoke lstrcpy,addr strBuffer,addr tmpDir
    invoke lstrcat,addr strBuffer,addr resName1
    invoke LoadLibrary,addr strBuffer
    .if eax == 0
        invoke MessageBox,0,addr ErrDll,addr caption,MB_ICONSTOP
        jmp exit
    .endif
    mov hDll,eax
  ;get function adresses
    invoke GetProcAddress,hDll,addr strROpenArchive
    mov ROpenArchive,eax
    invoke GetProcAddress,hDll,addr strRCloseArchive
    mov RCloseArchive,eax
    invoke GetProcAddress,hDll,addr strRReadHeader
    mov RReadHeader,eax
    invoke GetProcAddress,hDll,addr strRProcessFile
    mov RProcessFile,eax
    invoke GetProcAddress,hDll,addr strRSetCallback
    mov RSetCallback,eax
    invoke GetProcAddress,hDll,addr strRSetChangeVolProc
    mov RSetChangeVolProc,eax
    invoke GetProcAddress,hDll,addr strRSetProcessDataProc
    mov RSetProcessDataProc,eax
;-neu-:
    invoke GetProcAddress,hDll,addr strRSetPassword
    mov RSetPassword,eax

    ;load module filename as default archive name
    invoke GetModuleFileName,0,addr strBuffer,MAX_PATH
    invoke NameFromPath,addr strBuffer,addr srcDir  ;;NOTE: srcDir as tmp buffer used

  ;load ini-file values
    invoke lstrcpy,addr strBuffer,addr tmpDir
    invoke lstrcat,addr strBuffer,addr resName2

    ;get archive filename
    invoke GetPrivateProfileString,addr caption,addr fileKey,0,addr ArcName,63,addr strBuffer ;max 63 chars
    .if eax == 0
        invoke lstrlen,addr srcDir
        .if eax>63
            invoke MessageBox,0,addr ErrArcName,addr caption,MB_ICONSTOP
            jmp exit
        .endif
        inc eax ;terminating zero
        invoke lstrcpyn,addr ArcName,addr srcDir,eax
    .endif

    ;get target directory
    invoke GetPrivateProfileString,addr caption,addr pathKey,0,addr targetDir,MAX_PATH,addr strBuffer
    .if eax == 0
        invoke MessageBox,0,addr ErrIni,addr caption,MB_ICONSTOP
        jmp exit
    .endif

    ;get default dir
    invoke GetPrivateProfileString,addr caption,addr dirKey,0,addr targetDirName,MAX_PATH,addr strBuffer
    .if eax == 0
        invoke MessageBox,0,addr ErrIni,addr caption,MB_ICONSTOP
        jmp exit
    .endif
    ;get full uncompressed size
    invoke GetPrivateProfileString,addr caption,addr sizeKey,0,addr srcDir,20,addr strBuffer  ;max 20 digits
                                    ;;NOTE: srcDir as tmp buffer used
    invoke StrToFloat,addr srcDir,addr nBytesReq
    
    ;get patch filename
    invoke GetPrivateProfileString,addr caption,addr patchKey,0,addr PatchName,63,addr strBuffer  ;max 63 chars
    
    ;get app title
    invoke GetPrivateProfileString,addr caption,addr titleKey,0,addr AppTitle,127,addr strBuffer  ;max 127 chars
    
    ;get shortcuts
    invoke GetPrivateProfileInt,addr caption,addr shortcutsKey,3,addr strBuffer
    or flags,eax


  ;start Main App
	invoke Wizard  

exit:	

  ;free resources
    invoke FreeLibrary, hDll

  ;delete extracted resource files
    invoke lstrcpy,addr strBuffer,addr tmpDir
    invoke lstrcat,addr strBuffer,addr resName3
    invoke DeleteFile, addr strBuffer           ;delete license.nfo
    invoke lstrcpy,addr strBuffer,addr tmpDir
    invoke lstrcat,addr strBuffer,addr resName1
    invoke DeleteFile, addr strBuffer           ;delete unpacker.dll
    invoke lstrcpy,addr strBuffer,addr tmpDir
    invoke lstrcat,addr strBuffer,addr resName2
    invoke DeleteFile, addr strBuffer           ;delete eis.ini
    invoke RemoveDirectory,addr tmpDir

	invoke ExitProcess,0

;########################################################################

Wizard proc
	LOCAL	PropSheet[5]:PROPSHEETPAGE
	LOCAL	PropHdr:PROPSHEETHEADERA


	;Set up the 1st property sheet (WELCOME)
	mov		PropSheet.dwSize,sizeof PROPSHEETPAGE
	m2m		PropSheet.dwFlags,PSP_DEFAULT or PSP_HIDEHEADER
	m2m		PropSheet.hInstance,hInstance
	m2m		PropSheet.pszTemplate,IDD_WELCOME
	m2m		PropSheet.pfnDlgProc,offset WelcomeDlg
	;Set up the 2nd property sheet (NFO)
	mov		PropSheet[(sizeof PROPSHEETPAGE)].dwSize,sizeof PROPSHEETPAGE
	m2m		PropSheet[(sizeof PROPSHEETPAGE)].dwFlags,PSP_DEFAULT or PSP_USEHEADERSUBTITLE or PSP_USEHEADERTITLE
    m2m     PropSheet[(sizeof PROPSHEETPAGE)].pszHeaderTitle,offset nfoTitle
    m2m     PropSheet[(sizeof PROPSHEETPAGE)].pszHeaderSubTitle,offset nfoSTitle
	m2m		PropSheet[(sizeof PROPSHEETPAGE)].hInstance,hInstance
	m2m		PropSheet[(sizeof PROPSHEETPAGE)].pszTemplate,IDD_NFO
	m2m		PropSheet[(sizeof PROPSHEETPAGE)].pfnDlgProc,offset NfoDlg
	m2m		PropSheet[(sizeof PROPSHEETPAGE)].pszTitle,NULL
	mov		PropSheet[(sizeof PROPSHEETPAGE)].lParam,0
	mov		PropSheet[(sizeof PROPSHEETPAGE)].pfnCallback,0
	;Set up the 3rd property sheet (SETTINGS)
	mov		PropSheet[(sizeof PROPSHEETPAGE)*2].dwSize,sizeof PROPSHEETPAGE
	m2m		PropSheet[(sizeof PROPSHEETPAGE)*2].dwFlags,PSP_DEFAULT or PSP_USEHEADERSUBTITLE or PSP_USEHEADERTITLE 
    m2m     PropSheet[(sizeof PROPSHEETPAGE)*2].pszHeaderTitle,offset SettingsTitle
    m2m     PropSheet[(sizeof PROPSHEETPAGE)*2].pszHeaderSubTitle,offset SettingsSTitle
	m2m		PropSheet[(sizeof PROPSHEETPAGE)*2].hInstance,hInstance
	m2m		PropSheet[(sizeof PROPSHEETPAGE)*2].pszTemplate,IDD_SETTINGS
	m2m		PropSheet[(sizeof PROPSHEETPAGE)*2].pfnDlgProc,offset SettingsDlg
	m2m		PropSheet[(sizeof PROPSHEETPAGE)*2].pszTitle,NULL
	mov		PropSheet[(sizeof PROPSHEETPAGE)*2].lParam,0
	mov		PropSheet[(sizeof PROPSHEETPAGE)*2].pfnCallback,0
	;Set up the 4th property sheet (EXTRACT)
	mov		PropSheet[(sizeof PROPSHEETPAGE)*3].dwSize,sizeof PROPSHEETPAGE
	m2m		PropSheet[(sizeof PROPSHEETPAGE)*3].dwFlags,PSP_DEFAULT or PSP_USEHEADERSUBTITLE or PSP_USEHEADERTITLE
    m2m     PropSheet[(sizeof PROPSHEETPAGE)*3].pszHeaderTitle,offset ExtractTitle
    m2m     PropSheet[(sizeof PROPSHEETPAGE)*3].pszHeaderSubTitle,offset ExtractSTitle
	m2m		PropSheet[(sizeof PROPSHEETPAGE)*3].hInstance,hInstance
	m2m		PropSheet[(sizeof PROPSHEETPAGE)*3].pszTemplate,IDD_EXTRACT
	m2m		PropSheet[(sizeof PROPSHEETPAGE)*3].pfnDlgProc,offset ExtractDlg
	m2m		PropSheet[(sizeof PROPSHEETPAGE)*3].pszTitle,NULL
	mov		PropSheet[(sizeof PROPSHEETPAGE)*3].lParam,0
	mov		PropSheet[(sizeof PROPSHEETPAGE)*3].pfnCallback,0

	;Set up the 5th property sheet (CONSOLE)
	mov		PropSheet[(sizeof PROPSHEETPAGE)*4].dwSize,sizeof PROPSHEETPAGE
	m2m		PropSheet[(sizeof PROPSHEETPAGE)*4].dwFlags,PSP_DEFAULT or PSP_USEHEADERSUBTITLE or PSP_USEHEADERTITLE
    m2m     PropSheet[(sizeof PROPSHEETPAGE)*4].pszHeaderTitle,offset ConsoleTitle
    m2m     PropSheet[(sizeof PROPSHEETPAGE)*4].pszHeaderSubTitle,offset ConsoleSTitle
	m2m		PropSheet[(sizeof PROPSHEETPAGE)*4].hInstance,hInstance
	m2m		PropSheet[(sizeof PROPSHEETPAGE)*4].pszTemplate,IDD_CONSOLE
	m2m		PropSheet[(sizeof PROPSHEETPAGE)*4].pfnDlgProc,offset ConsoleDlg
	m2m		PropSheet[(sizeof PROPSHEETPAGE)*4].pszTitle,NULL
	mov		PropSheet[(sizeof PROPSHEETPAGE)*4].lParam,0
	mov		PropSheet[(sizeof PROPSHEETPAGE)*4].pfnCallback,0

	
	; Create the 5 Pages
	invoke CreatePropertySheetPage,addr PropSheet
	mov		hPs[0],eax
	invoke CreatePropertySheetPage,addr PropSheet[sizeof PROPSHEETPAGE]
	mov		hPs[4],eax
	invoke CreatePropertySheetPage,addr PropSheet[(sizeof PROPSHEETPAGE)*2]
	mov		hPs[8],eax
    invoke CreatePropertySheetPage,addr PropSheet[(sizeof PROPSHEETPAGE)*3]
	mov		hPs[12],eax
    invoke CreatePropertySheetPage,addr PropSheet[(sizeof PROPSHEETPAGE)*4]
	mov		hPs[16],eax

	; Set up the property sheet header
	mov		PropHdr.dwSize,sizeof PropHdr
	mov		PropHdr.dwFlags,PSH_WIZARD97 or PSH_HEADER or PSH_WATERMARK
	m2m		PropHdr.hwndParent,NULL
	m2m		PropHdr.hInstance,hInstance
	mov		PropHdr.nPages,5
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

WelcomeDlg proc hWin:HWND,uMsg:DWORD,wParam:WPARAM,lParam:LPARAM

      LOCAL Wwd  :DWORD
      LOCAL Wht  :DWORD
      LOCAL Wtx  :DWORD
      LOCAL Wty  :DWORD
      LOCAL rect :RECT
      LOCAL hParent:HANDLE
      LOCAL hMenu:HANDLE
      LOCAL msg:MSG
      
    invoke GetParent,hWin
    mov dummy_dd,eax
    invoke PeekMessage,addr msg,eax,WM_SYSCOMMAND,WM_SYSCOMMAND,PM_REMOVE
    .if msg.message == WM_SYSCOMMAND
        .if msg.wParam==333
            invoke PeekMessage,addr msg,eax,WM_SYSCOMMAND,WM_SYSCOMMAND,PM_REMOVE
            invoke MessageBox,hWin,addr MsgAbout,addr caption,MB_OK
        .else
            invoke GetParent,hWin
            invoke PostMessage,eax,WM_SYSCOMMAND,msg.wParam,msg.lParam
        .endif
    .endif

    mov	eax,uMsg  

	.if eax==WM_COMMAND
		mov eax,wParam
		and	eax,0FFFFh  ;get loword of wParam
		
    ;.elseif eax==WM_LBUTTONDOWN ;secret about button
    ;    mov eax,lParam
    ;    .if ax <20
    ;        shr eax,16
    ;        .if ax <20
    ;            invoke MessageBox,hWin,addr MsgAbout,addr caption,MB_OK                            
    ;        .endif
    ;    .endif

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

       ; load bitmap
        invoke BitmapFromResource,hInstance,103
        mov hLogo_big,eax

               
       ; load title font
        invoke lstrcpy,addr lFont2.lfFaceName,addr FontName2
        mov lFont2.lfHeight,20
        mov lFont2.lfWeight,FW_BOLD
   		invoke CreateFontIndirect,addr lFont2
        mov hFont2,eax
   		invoke SendDlgItemMessage,hWin,1002,WM_SETFONT,eax,TRUE
   		invoke SendDlgItemMessage,hWin,1002,WM_SETTEXT,0,addr AppTitle ;print app title
   		
       ; set texts
        invoke SendDlgItemMessage,hWin,4003,WM_SETTEXT,0,addr DlgItemTxt4003
        invoke SendDlgItemMessage,hWin,4004,WM_SETTEXT,0,addr DlgItemTxt4004
   		

       ; set sys menu item (about-box)
        invoke GetSystemMenu,hParent,0
        mov hMenu,eax          ;;todo: closehandle!
        invoke AppendMenu,hMenu,MF_SEPARATOR,0,0
        invoke AppendMenu,hMenu,MF_STRING,333,addr AboutStr
        ;invoke SetMenuItemBitmaps,hMenu,0,MF_BYPOSITION,eax,eax
        ;invoke DrawMenuBar,hParent


    .elseif eax==WM_PAINT
        invoke PaintProc,hWin,hLogo_big,250,340

	.elseif	eax==WM_NOTIFY
		mov	edx,lParam
		mov	eax,NMHDR.code[edx]

		.if eax==PSN_SETACTIVE
            
			;page gaining focus
			m2m    hPropSheet,NMHDR.hwndFrom[edx]
            invoke SendMessage,hPropSheet,PSM_SETTITLE,0, addr DlgItemTxt4000 ;sets page title
			invoke PostMessage,hPropSheet,PSM_SETWIZBUTTONS,0,PSWIZB_NEXT ;;todo: "back"-Knopf komplett verstecken
			invoke SetWindowLong,hWin,DWL_MSGRESULT,0  ;return FALSE
	
		.elseif eax==PSN_KILLACTIVE
			;page loosing focus
            invoke GetParent,hWin
            mov hParent,eax     ;;todo:das mal richtig hinbekommen mit dem about!
			invoke GetSystemMenu,hParent,0
			mov hMenu,eax
			invoke DeleteMenu,hMenu,3,MF_BYPOSITION
			invoke DeleteMenu,hMenu,2,MF_BYPOSITION			
			invoke DrawMenuBar,hParent
			invoke SetWindowLong,hWin,DWL_MSGRESULT,0

		.elseif eax==PSN_RESET
			;Add own cancel code here

		.endif
    
    .elseif eax==WM_DESTROY
;		invoke DeleteObject,hLogo            
		invoke DeleteObject,hLogo_big
 		invoke DeleteObject,hFont2 ;free font
		invoke DeleteObject,hFont ;free font (handle is valid if you viewed the nfo dlg before!)

	.else
		return FALSE
	.endif
	return TRUE

WelcomeDlg endp

NfoDlg proc hWin:HWND,uMsg:DWORD,wParam:WPARAM,lParam:LPARAM

	; NFO dialog
  
	mov		eax,uMsg  

	.if eax==WM_COMMAND
		mov eax,wParam
		and eax,0FFFFh

	.elseif eax==WM_INITDIALOG
        m2m		hPsDlg[4],hWin
        ;load font
        invoke lstrcpy,addr lFont.lfFaceName,addr FontName
        mov lFont.lfHeight,9
        mov lFont.lfWeight,FW_REGULAR
    	mov lFont.lfCharSet,OEM_CHARSET
    	invoke CreateFontIndirect,addr lFont
        mov hFont,eax
    	invoke SendDlgItemMessage,hWin,1001,WM_SETFONT,hFont,TRUE
    	invoke SetDlgItemText,hWin,1001,nfoAddress

   	.elseif uMsg==WM_CTLCOLORSTATIC
      	;invoke SetTextColor,wParam,Green
    	invoke SetBkColor,wParam,00FFDFDFh
		invoke GetStockObject,BLACK_BRUSH    	
		ret

	.elseif	eax==WM_NOTIFY
		mov	edx,lParam
		mov	eax,NMHDR.code[edx]

		.if eax==PSN_SETACTIVE
			;page gaining focus
			m2m    hPropSheet,NMHDR.hwndFrom[edx]
            invoke SendMessage,hPropSheet,PSM_SETTITLE,0, addr DlgItemTxt1000 ;sets page title			
			invoke SetWindowLong,hWin,DWL_MSGRESULT,0
			invoke PostMessage,hPropSheet,PSM_SETWIZBUTTONS,0,PSWIZB_NEXT or PSWIZB_BACK

		.elseif eax==PSN_KILLACTIVE
			;page loosing focus
    	    mov eax,flags  ;test if license has already been accepted
		    and eax,FLAG_LIC_READ
		    .if ZERO?
	       		invoke MessageBox,hWin,addr MsgLicense,addr caption,MB_YESNO or MB_ICONQUESTION
    			.if eax==IDYES
        			invoke SetWindowLong,hWin,DWL_MSGRESULT,0
        			or flags,FLAG_LIC_READ
                .else
                    invoke SetWindowLong,hWin,DWL_MSGRESULT,1
    			.endif
		    .endif

		.elseif eax==PSN_RESET
			;Add own cancel code here
		
		.endif
		
    .elseif eax==WM_DESTROY
;		invoke DeleteObject,hLogo 
		invoke DeleteObject,hLogo_big
 		invoke DeleteObject,hFont2 ;free welcome dlg font
		invoke DeleteObject,hFont ;free nfo font

	.else
		return FALSE
	.endif
	return TRUE

NfoDlg endp

SettingsDlg proc hWin:HWND,uMsg:DWORD,wParam:WPARAM,lParam:LPARAM
	; Settings dialog

	mov	eax,uMsg  


    .if eax==WM_COMMAND
		mov 	eax,wParam
		and		eax,0FFFFh
		
        .if eax==5007 ;-->browse...
            invoke DialogBoxParam,hInstance,5500,hWin,addr BrowseProc,0
            invoke lstrcpy,addr strBuffer,addr targetDir   ;copy path to buffer
            invoke lstrlen,addr strBuffer
            .if eax != 3    ;if not root dir,append "\"
                mov dummy_dd,"\"
                invoke lstrcat,addr strBuffer,addr dummy_dd
          .endif
            invoke lstrcat,addr strBuffer,addr targetDirName  ;append dirname
            invoke SendDlgItemMessage,hWin,5001,WM_SETTEXT,0,addr strBuffer
            invoke SpaceCheck,hWin
        .endif
	
    .elseif eax==WM_INITDIALOG
        m2m		hPsDlg[8],hWin
        ;invoke BitmapFromResource,hInstance,100
        ;mov hLogo,eax
        
       ; set texts 
        invoke SendDlgItemMessage,hWin,5002,WM_SETTEXT,0,addr DlgItemTxt5002
        invoke SendDlgItemMessage,hWin,5003,WM_SETTEXT,0,addr DlgItemTxt5003
        invoke SendDlgItemMessage,hWin,5013,WM_SETTEXT,0,addr DlgItemTxt5013
        invoke SendDlgItemMessage,hWin,5014,WM_SETTEXT,0,addr DlgItemTxt5014
        invoke SendDlgItemMessage,hWin,5007,WM_SETTEXT,0,addr DlgItemTxt5007
        invoke SendDlgItemMessage,hWin,5008,WM_SETTEXT,0,addr DlgItemTxt5008
        invoke SendDlgItemMessage,hWin,5009,WM_SETTEXT,0,addr DlgItemTxt5009
        invoke SendDlgItemMessage,hWin,5010,WM_SETTEXT,0,addr DlgItemTxt5010
        invoke SendDlgItemMessage,hWin,5011,WM_SETTEXT,0,addr DlgItemTxt5011
        invoke SendDlgItemMessage,hWin,5012,WM_SETTEXT,0,addr DlgItemTxt5012

        invoke lstrcpyn,addr dummy_dd,addr targetDir,4      ;copy "X:\",0
        invoke GetDriveType,addr dummy_dd
        .if (eax < 3) || (eax > 4)
            mov targetDir, "C"      ;if targetdrive is invalid change it to "C:\"
        .endif

        invoke GetCurrentDirectory,MAX_PATH,addr srcDir
        invoke lstrcpy,addr strBuffer,addr targetDir    ;make copy for concatenation
        .if eax != 3
            mov dummy_dd,"\"
            invoke lstrcat,addr strBuffer,addr dummy_dd
        .endif
        invoke lstrcat,addr strBuffer,addr targetDirName
        invoke SendDlgItemMessage,hWin,5001,WM_SETTEXT,0,addr strBuffer     ;print path
        mov eax,nMBytesReq
        .if eax == 0 ;go and get that value
            finit
            fld nBytesReq
            fidiv oneMeg
            fistp nMBytesReq
            invoke wsprintf,addr strBuffer,addr nFormatStr,nMBytesReq
            invoke SendDlgItemMessage,hWin,5004,WM_SETTEXT,0,addr strBuffer  ;print bytes required
        .endif
        mov eax,flags
        and eax,FLAG_SCSMENU
        .if ZERO?
            invoke GetDlgItem,hWin,5002
            invoke EnableWindow,eax,FALSE
        .endif
        mov eax,flags
        and eax,FLAG_SCDESKTOP
        .if ZERO?
            invoke GetDlgItem,hWin,5003
            invoke EnableWindow,eax,FALSE
        .endif
        
    ;.elseif eax==WM_PAINT
        ;invoke PaintProc,hWin,hLogo,110,260

    .elseif	eax==WM_NOTIFY
		mov	edx,lParam
		mov	eax,NMHDR.code[edx]
	
        .if eax==PSN_SETACTIVE
			;page gaining focus
			m2m    hPropSheet,NMHDR.hwndFrom[edx]
            invoke SendMessage,hPropSheet,PSM_SETTITLE,0, addr DlgItemTxt5000 ;sets page title			
			invoke SetWindowLong,hWin,DWL_MSGRESULT,0
            invoke SpaceCheck,hWin
            mov eax,flags
            and eax,FLAG_SCSMENU       ;startmenu link?
            .if !ZERO?
                invoke CheckDlgButton,hWin,5002,BST_CHECKED
            .endif
            mov eax,flags
            and eax,FLAG_SCDESKTOP      ;desktop link?
            .if !ZERO?
                invoke CheckDlgButton,hWin,5003,BST_CHECKED
            .endif

		.elseif eax==PSN_KILLACTIVE
			;page loosing focus (goto extract page)
            invoke SetCurrentDirectory,addr srcDir ;needed because of BrowseProc
            invoke lstrlen,addr targetDir
            .if eax != 3
                mov dummy_dd,"\"
                invoke lstrcat,addr targetDir,addr dummy_dd
            .endif
            invoke lstrcat,addr targetDir,addr targetDirName
            invoke SetWindowLong,hWin,DWL_MSGRESULT,0
            invoke IsDlgButtonChecked,hWin,5002
            .if eax==BST_CHECKED
                or flags,FLAG_SCSMENU
            .else
                and flags,0FFFFFFFFh-FLAG_SCSMENU
            .endif
            invoke IsDlgButtonChecked,hWin,5003
            .if eax==BST_CHECKED
                or flags,FLAG_SCDESKTOP
            .else
                and flags,0FFFFFFFFh-FLAG_SCDESKTOP
            .endif

		.elseif eax==PSN_RESET
			;Add own cancel code here
		.endif
        
    .elseif eax==WM_DESTROY
;		invoke DeleteObject,hLogo
		invoke DeleteObject,hLogo_big
 		invoke DeleteObject,hFont2 ;free welcome dlg font
		invoke DeleteObject,hFont ;free nfo font

    .else
		return FALSE
	.endif
	return TRUE

SettingsDlg endp

ExtractDlg	proc hWin:DWORD,uMsg:DWORD,wParam:WPARAM,lParam:LPARAM
	; This dialog processes property page 3

	mov	eax,uMsg

	.if eax==WM_COMMAND
		mov 	eax,wParam
		and		eax,0FFFFh

	.elseif eax==WM_INITDIALOG
		m2m		hPsDlg[12],hWin
		m2m     hExtract,hWin
        invoke SendDlgItemMessage,hExtract,3001,PBM_SETBARCOLOR,0,0
        invoke SendDlgItemMessage,hExtract,3004,PBM_SETBARCOLOR,0,0
        invoke SendDlgItemMessage,hWin,3009,WM_SETTEXT,0,addr srcDir
        invoke SendDlgItemMessage,hWin,3007,WM_SETTEXT,0,addr targetDir

       ;set texts
        invoke SendDlgItemMessage,hWin,3003,WM_SETTEXT,0,addr DlgItemTxt3003
        invoke SendDlgItemMessage,hWin,3006,WM_SETTEXT,0,addr DlgItemTxt3006       
        invoke SendDlgItemMessage,hWin,3008,WM_SETTEXT,0,addr DlgItemTxt3008
        invoke SendDlgItemMessage,hWin,3010,WM_SETTEXT,0,addr DlgItemTxt3010        
        invoke SendDlgItemMessage,hWin,3012,WM_SETTEXT,0,addr DlgItemTxt3012        


      ;create extraction thread
        mov ebx,OFFSET ExtractThread
        invoke CreateThread,0,0,ebx,NULL,NULL,addr ThreadID ;can be the same ID for ExtractThread & ConsoleThread
        mov hThread,eax                                     ;because they never exist at the same time

    .elseif eax==WM_PAINT
        invoke PaintProc,hWin,hLogo,110,260

	.elseif	eax==WM_NOTIFY
		mov		edx,lParam
		mov		eax,NMHDR.code[edx]
		.if eax==PSN_SETACTIVE		; page gaining focus
			m2m		hPropSheet,NMHDR.hwndFrom[edx]
            invoke SendMessage,hPropSheet,PSM_SETTITLE,0, addr DlgItemTxt3000 ;sets page title			
			invoke PostMessage,hPropSheet,PSM_SETWIZBUTTONS,0,0
			invoke SetWindowLong,hWin,DWL_MSGRESULT,0

		.elseif eax==PSN_KILLACTIVE
			;page loosing focus
			invoke CloseHandle,hThread
			invoke SetWindowLong,hWin,DWL_MSGRESULT,0
			
		.elseif eax==PSN_WIZNEXT

        .elseif eax == PSN_QUERYCANCEL
            ;check if there where error opening the archive
            invoke Sleep,10 ;give thread time to finish
            invoke GetExitCodeThread,hThread,addr dummy_dd
            .if dummy_dd==0
	       		invoke CloseHandle,hLogo_big
      			invoke SetWindowLong,hWin,DWL_MSGRESULT,FALSE ;set FALSE
      			ret
            .endif
            invoke SuspendThread,hThread
            invoke MessageBox,hWin,addr MsgExit,addr caption,MB_ICONQUESTION or MB_YESNO
            .if eax == IDYES
                not abort_thread ;set abort-flag=1
                ;;todo: dlgbox fuer die zeit waehrend des Beendens: "bitte waren während das Programm beendet wird..."
                invoke ResumeThread,hThread
              try_again:
                invoke GetExitCodeThread,hThread,addr dummy_dd
                .if dummy_dd == STILL_ACTIVE
                    invoke Sleep,100
                    jmp try_again
                .endif
				invoke CloseHandle,hThread
	       		invoke CloseHandle,hLogo_big
      			invoke SetWindowLong,hWin,DWL_MSGRESULT,FALSE ;set FALSE
            .else
                invoke ResumeThread,hThread
       			invoke SetWindowLong,hWin,DWL_MSGRESULT,TRUE ;set TRUE
       	    .endif

		.endif
		
    .elseif eax==WM_DESTROY
		invoke DeleteObject,hLogo_big
 		invoke DeleteObject,hFont2 ;free welcome dlg font
		invoke DeleteObject,hFont ;free nfo font

	.else
		return FALSE
	.endif
	return TRUE

ExtractDlg	endp

ExtractThread PROC 

    invoke CharToOem,addr targetDir,addr strBuffer ;convert ansi -> ascii
    invoke lstrcpy,addr targetDir,addr strBuffer

  ;open Archive
    mov ArchiveData.lpArcName, offset ArcName
    mov ArchiveData.OpenMode, RAR_OM_EXTRACT ;open archive for extraction
    push offset ArchiveData
    call ROpenArchive
    .if eax == 0 ;error
        .if ArchiveData.OpenResult == ERAR_NO_MEMORY
            invoke MessageBox,hExtract,addr RNoMemoryMsg,addr caption,MB_ICONSTOP
        .elseif ArchiveData.OpenResult == ERAR_BAD_DATA
            invoke MessageBox,hExtract,addr RBadDataMsg,addr caption,MB_ICONSTOP
        .elseif ArchiveData.OpenResult == ERAR_BAD_ARCHIVE
            invoke MessageBox,hExtract,addr RBadArchiveMsg,addr caption,MB_ICONSTOP
        .elseif ArchiveData.OpenResult == ERAR_EOPEN
            invoke MessageBox,hExtract,addr REOpenMsg,addr caption,MB_ICONSTOP
        .endif
        invoke PostMessage,hPropSheet,PSM_PRESSBUTTON,PSBTN_CANCEL,0
        return 0
    .endif
    mov hArchive, eax
  ;write current archivename to window
    invoke lstrcpy,addr strBuffer,addr ArcName
    invoke SendDlgItemMessage,hExtract,3013,WM_SETTEXT,0,addr strBuffer

  ;set password
    szText pass, 00h,"123456789ABCDEF"  ;change string here, if you want to use password protected archives
    push offset pass
    push hArchive
    call RSetPassword

  ;get uncompressed size
_extract:
    push offset HeaderData
    push hArchive
    call RReadHeader
    .if eax == ERAR_END_ARCHIVE
        jmp extract_
    .elseif eax == ERAR_BAD_DATA
        invoke MessageBox,hExtract,addr RBadDataMsg,addr caption,MB_ICONSTOP
        ; ->exit is not needed
    .endif
    push 0
    push offset RARCallbackProc
    push hArchive
    call RSetCallback
    invoke SendDlgItemMessage,hExtract,3002,WM_SETTEXT,0,addr HeaderData.FileName
    push 0
    push offset targetDir
    push RAR_EXTRACT
    push hArchive
    call RProcessFile
    .if eax == 0    ;success
        jmp _extract
    .elseif eax == ERAR_BAD_DATA ;File CRC error
        invoke MessageBox,hExtract,addr RBadDataMsg2,addr caption,MB_ICONSTOP
    .elseif eax == ERAR_BAD_ARCHIVE ;Volume is not valid RAR archive
        invoke MessageBox,hExtract,addr RBadArchiveMsg,addr caption,MB_ICONSTOP
    .elseif eax == ERAR_UNKNOWN_FORMAT ;Unknown archive format
        invoke MessageBox,hExtract,addr RBadArchiveMsg,addr caption,MB_ICONSTOP
    .elseif eax == ERAR_EOPEN ;Volume open error
        invoke MessageBox,hExtract,addr REOpenMsg,addr caption,MB_ICONSTOP
    .elseif eax == ERAR_ECREATE ;File create error
        invoke MessageBox,hExtract,addr RECreateMsg,addr caption,MB_ICONSTOP
    .elseif eax == ERAR_ECLOSE ;File close error
        invoke MessageBox,hExtract,addr RECloseMsg,addr caption,MB_ICONSTOP
    .elseif eax == ERAR_EREAD ;Read error
        invoke MessageBox,hExtract,addr REReadMsg,addr caption,MB_ICONSTOP
    .elseif eax == ERAR_EWRITE ;Write error
        invoke MessageBox,hExtract,addr REWriteMsg,addr caption,MB_ICONSTOP
    .elseif eax == ERAR_UNKNOWN
        .if abort_thread == 1
            push hArchive
            call RCloseArchive
            .if eax != 0
                invoke MessageBox,hExtract,addr RECloseMsg,addr caption,MB_ICONSTOP
            .endif
            return 0
        .endif
        invoke MessageBox,hExtract,addr REUnknown,addr caption,MB_ICONSTOP
    .else
        invoke ErrorCode,hExtract,eax
    .endif
  ;close dialogs
    invoke PostMessage,hExtract,WM_DESTROY,0,0
    return 0

;;todo: eigener proc fürs entpacken - dann kann der für die patch file wiederverwendet werden

extract_:  
  ;close Archive
    push hArchive
    call RCloseArchive
    .if eax != 0
        invoke MessageBox,hExtract,addr RECloseMsg,addr caption,MB_ICONSTOP
        ;;todo: ->exit?
    .endif

  ;-----------------------------
  ;open patch archive (and get size)
    mov ArchiveData.lpArcName, offset PatchName
    mov ArchiveData.OpenMode, RAR_OM_LIST
    push offset ArchiveData
    call ROpenArchive
    .if eax == 0 ;error
        .if ArchiveData.OpenResult == ERAR_NO_MEMORY
            invoke MessageBox,hExtract,addr RNoMemoryMsg,addr caption,MB_ICONSTOP
        .elseif ArchiveData.OpenResult == ERAR_BAD_DATA
            invoke MessageBox,hExtract,addr RBadDataMsg,addr caption,MB_ICONSTOP
        .elseif ArchiveData.OpenResult == ERAR_BAD_ARCHIVE
            invoke MessageBox,hExtract,addr RBadArchiveMsg,addr caption,MB_ICONSTOP
        .elseif ArchiveData.OpenResult == ERAR_EOPEN
            jmp nopatch
        .endif
        jmp nopatch ;do not abort if patch file is not correct
    .endif
    mov hArchive, eax
  ;get full uncompressed size
    mov patchSize,0
_getsize:
    push offset HeaderData
    push hArchive
    call RReadHeader
    .if eax == ERAR_END_ARCHIVE
        jmp getsize_
    .elseif eax == ERAR_BAD_DATA
        invoke MessageBox,hExtract,addr RBadDataMsg,addr caption,MB_ICONSTOP
    .endif
    mov eax,HeaderData.UnpSize
    add patchSize,eax
    push 0
    push 0
    push RAR_SKIP
    push hArchive
    call RProcessFile
    .if eax == 0
        jmp _getsize
    .endif
getsize_:
  ;close Patch Archive
    push hArchive
    call RCloseArchive
    .if eax != 0
        invoke MessageBox,hExtract,addr RECloseMsg,addr caption,MB_ICONSTOP
    .endif
    finit
    fldz    ;load 0.0
    fst nOverallBytesExtracted ;clear var
    fild patchSize ;load patchfile size
    fst nBytesReq  ;save patchfile size to nBytesReq
  ;re-open patch archive for extraction
    mov ArchiveData.lpArcName, offset PatchName
    mov ArchiveData.OpenMode, RAR_OM_EXTRACT
    push offset ArchiveData
    call ROpenArchive ;error routines not needed here because archive was used earlier !!!
    mov hArchive, eax
  ;write current archivename to window
    invoke lstrcpy,addr strBuffer,addr PatchName
    invoke SendDlgItemMessage,hExtract,3013,WM_SETTEXT,0,addr strBuffer
    push 0
    push offset RARCallbackProc
    push hArchive
    call RSetCallback
_extract2:
    push offset HeaderData
    push hArchive
    call RReadHeader
    .if eax == ERAR_END_ARCHIVE
        jmp extract2_
    .elseif eax == ERAR_BAD_DATA
        invoke MessageBox,hExtract,addr RBadDataMsg,addr caption,MB_ICONSTOP
    .endif
    invoke SendDlgItemMessage,hExtract,3002,WM_SETTEXT,0,addr HeaderData.FileName
    push 0
    push offset targetDir
    push RAR_EXTRACT
    push hArchive
    call RProcessFile
    .if eax == 0    ;success
        jmp _extract2
    .elseif eax == ERAR_BAD_DATA ;File CRC error
        invoke MessageBox,hExtract,addr RBadDataMsg2,addr caption,MB_ICONSTOP
    .elseif eax == ERAR_BAD_ARCHIVE ;Volume is no valid RAR archive
        invoke MessageBox,hExtract,addr RBadArchiveMsg,addr caption,MB_ICONSTOP
    .elseif eax == ERAR_UNKNOWN_FORMAT ;Unknown archive format
        invoke MessageBox,hExtract,addr RBadArchiveMsg,addr caption,MB_ICONSTOP
    .elseif eax == ERAR_EOPEN ;Volume open error
        invoke MessageBox,hExtract,addr REOpenMsg,addr caption,MB_ICONSTOP
    .elseif eax == ERAR_ECREATE ;File create error
        invoke MessageBox,hExtract,addr RECreateMsg,addr caption,MB_ICONSTOP
    .elseif eax == ERAR_ECLOSE ;File close error
        invoke MessageBox,hExtract,addr RECloseMsg,addr caption,MB_ICONSTOP
    .elseif eax == ERAR_EREAD ;Read error
        invoke MessageBox,hExtract,addr REReadMsg,addr caption,MB_ICONSTOP
    .elseif eax == ERAR_EWRITE ;Write error
        invoke MessageBox,hExtract,addr REWriteMsg,addr caption,MB_ICONSTOP
    .elseif eax == ERAR_UNKNOWN
        .if abort_thread == 1
            push hArchive
            call RCloseArchive
            .if eax != 0
                invoke MessageBox,hExtract,addr RECloseMsg,addr caption,MB_ICONSTOP
            .endif
            return 0
        .endif
        invoke MessageBox,hExtract,addr REUnknown,addr caption,MB_ICONSTOP
    .else
        invoke ErrorCode,hExtract,eax        
    .endif
  ;do not close dialogs here

extract2_:  
  ;close Archive
    push hArchive
    call RCloseArchive
    .if eax != 0
        invoke MessageBox,hExtract,addr RECloseMsg,addr caption,MB_ICONSTOP
    .endif

nopatch:  
    .if abort_thread == 1  ;has thread been aborted?
        return 0
    .endif
    invoke SendMessage,hPropSheet,PSM_SETWIZBUTTONS,0,PSWIZB_NEXT ;enable next button
    invoke PostMessage,hPropSheet,PSM_PRESSBUTTON,PSBTN_NEXT,0
    .if abort_thread == 1  ;has thread been aborted?
        not abort_thread
        return 0
    .endif   

    invoke OemToChar,addr targetDir,addr strBuffer ;convert string back to ansi
    invoke lstrcpy,addr targetDir,addr strBuffer


    return 1  ;extraction went ok
    
ExtractThread endp

ConsoleDlg proc hWin:HWND,uMsg:DWORD,wParam:WPARAM,lParam:LPARAM
	; This dialog processes property page 2
    ;;LOCAL buf[128]:BYTE
    
	mov	eax,uMsg

	.if eax==WM_COMMAND
		mov 	eax,wParam
		and		eax,0FFFFh

	.elseif eax==WM_INITDIALOG
		m2m		hPsDlg[16],hWin

        invoke GetDlgItem,hWin,2001 ;get EditBox handle
        mov hwndEdit,eax     
			
        ;hFont has to be initialisec in WizNfoDlg !!!
        invoke SendDlgItemMessage,hWin,2001,WM_SETFONT,hFont,TRUE
			
        ;redirect thread proc
        mov edx,OFFSET ConsoleThread
        invoke CreateThread,0,0,edx,NULL,NORMAL_PRIORITY_CLASS,addr ThreadID ;ThreadID already uses in ExtractDlg
        mov hThread,eax  ;hThread already used in ExtractDlg - just as info :-)

;    .elseif eax==WM_PAINT
;        invoke PaintProc,hWin,hLogo,110,260

   	.elseif uMsg==WM_CTLCOLORSTATIC
      	invoke SetTextColor,wParam,Green
    	invoke SetBkColor,wParam,Black
		invoke GetStockObject,BLACK_BRUSH    	
		ret

	.elseif	eax==WM_NOTIFY
		mov		edx,lParam
		mov		eax,NMHDR.code[edx]
		
		.if eax==PSN_SETACTIVE
			;page gaining focus
			m2m hPropSheet,NMHDR.hwndFrom[edx]
            invoke SendMessage,hPropSheet,PSM_SETTITLE,0, addr DlgItemTxt2000 ;sets page title			
            invoke PostMessage,hPropSheet,PSM_SETWIZBUTTONS,0,PSWIZB_DISABLEDFINISH
			invoke SetWindowLong,hWin,DWL_MSGRESULT,0

		.elseif eax==PSN_KILLACTIVE
			;page loosing focus
			invoke SetWindowLong,hWin,DWL_MSGRESULT,0
			invoke CloseHandle,hThread			
        
        .elseif eax==PSN_WIZFINISH
            ;clean up
			invoke CloseHandle,hThread
;            invoke DeleteObject,hLogo
            invoke DeleteObject,hLogo_big
            invoke DeleteObject,hFont2 ;free welcome dlg font
            invoke DeleteObject,hFont ;free nfo font
        
        .elseif eax==PSN_RESET

		.endif

    .elseif eax==WM_DESTROY   
        ;clean up
        ;;todo: aendern,sobald ein End-Dialog da sein sollte
        invoke CloseHandle,hThread
;        invoke DeleteObject,hLogo
        invoke DeleteObject,hLogo_big
        invoke DeleteObject,hFont2 ;free welcome dlg font
        invoke DeleteObject,hFont ;free nfo font

	.else
		return FALSE
	.endif
	return TRUE

ConsoleDlg	endp

ConsoleThread PROC 
    LOCAL hRead:DWORD
    LOCAL hWrite:DWORD
    LOCAL sat:SECURITY_ATTRIBUTES
    LOCAL startupinfo:STARTUPINFO
	LOCAL pinfo:PROCESS_INFORMATION
	LOCAL buffer[1024]:byte
	LOCAL bytesRead:DWORD

        ;;todo: 2-way console-box
        ;;todo: groesse reservieren fuer envfile

  ;get & set some env vars
    invoke lstrcat,addr env,addr targetDir
    invoke lstrcat,addr env,addr envSMenu
   ;get path for desktop
    invoke RegCreateKeyEx,HKEY_LOCAL_MACHINE,addr ShellFoldersKey,0,0,REG_OPTION_NON_VOLATILE,KEY_ALL_ACCESS,0,addr phkResult,addr lpdwDisp
    mov dummy_dd,MAX_PATH
    invoke RegQueryValueEx,phkResult,addr KeySMenu,0,0,addr strBuffer,addr dummy_dd
	invoke lstrcat,addr env,addr strBuffer
    invoke lstrcat,addr env,addr envDesktop
    invoke RegQueryValueEx,phkResult,addr KeyDesktop,0,0,addr strBuffer,addr dummy_dd
	invoke lstrcat,addr env,addr strBuffer
	invoke RegCloseKey, phkResult

	invoke lstrcat,addr env,addr envWindir
    invoke GetWindowsDirectory,addr strBuffer,128
    invoke lstrcat,addr env,addr strBuffer
    
    ;set shortcut options
    invoke lstrcat,addr env,addr envSCuts
    push 0
    pop dummy_dd
    mov eax,flags
    and eax,FLAG_SCSMENU or FLAG_SCDESKTOP
    invoke udw2str,eax,addr dummy_dd
    invoke lstrcat,addr env,addr dummy_dd
    invoke CharToOem,addr env,addr strBuffer    ;convert ansi -> ascii
    invoke lstrcpy,addr env,addr strBuffer

    invoke lstrcpy,addr strBuffer,addr targetDir
    invoke lstrcat,addr strBuffer,addr envFile
    invoke CreateFile,addr strBuffer,GENERIC_WRITE,FILE_SHARE_READ,0,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0
    .if eax==INVALID_HANDLE_VALUE
    	invoke MessageBox,0,addr ErrEnv,addr caption,MB_ICONSTOP+MB_OK ;;todo: parent, continue?
    .endif
    mov hEnvFile,eax
    invoke lstrlen,addr env
    mov ebx,eax
    invoke WriteFile,hEnvFile,addr env,ebx,addr dummy_dd,0
    invoke CloseHandle,hEnvFile
    
    ;create pipe
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
       ;execute setup.bat
        invoke SetCurrentDirectory,addr targetDir
        invoke GetEnvironmentVariable,addr ComSpec,addr strBuffer,MAX_PATH
        invoke lstrcat,addr strBuffer,addr RunFile2
        invoke lstrcat,addr strBuffer,addr targetDir
        invoke lstrcat,addr strBuffer,addr RunFile
       ;create process
        invoke CreateProcess,NULL,addr strBuffer,NULL,NULL,TRUE,NULL,NULL,NULL,addr startupinfo,addr pinfo
        .if eax==NULL
            invoke MessageBox,0,addr ErrMsg,addr caption,MB_ICONERROR or MB_OK ;;todo: PARENT,Fehlermeldung
        .else
            invoke CloseHandle,hWrite
            invoke lstrcpy,addr strBuffer,addr targetDir ;dummy-file 
            invoke lstrcat,addr strBuffer,addr doneFile  ;dummy-file   ;;todo: gescheite loesung fuer DOS-Box close!
            .while TRUE
                invoke RtlZeroMemory,addr buffer,1024
                invoke ReadFile,hRead,addr buffer,1023,addr bytesRead,NULL
                .if eax==NULL
                    .break
                .else
                    invoke SendMessage,hwndEdit,EM_SETSEL,-1,0
                    invoke SendMessage,hwndEdit,EM_REPLACESEL,FALSE,addr buffer
                    invoke exist,addr strBuffer
                    .if eax==1          ;done file created?
                        invoke DeleteFile,addr strBuffer
                        .break      ;well, than it's done...
                    .endif
                .endif
            .endw
		.endif
        invoke CloseHandle,hRead ;close handle on setup.bat
        invoke lstrcpy,addr strBuffer,addr targetDir    ;delete setup.bat
        invoke lstrcat,addr strBuffer,addr RunFile      ; -.-
        invoke DeleteFile,addr strBuffer                ; -.-
    .endif
    invoke PostMessage,hPropSheet,PSM_SETWIZBUTTONS,0,PSWIZB_FINISH;enable finish button
    invoke PostMessage,hPropSheet,PSM_CANCELTOCLOSE,0,0 ;disable cancel button
    invoke PostMessage,hPropSheet,PSM_SETHEADERSUBTITLE,4,addr ConsoleSTitle2
    invoke PostMessage,hPropSheet,PSM_SETTITLE,0,addr ConsoleTitle2
    invoke SetWindowLong,hPropSheet,DWL_MSGRESULT,1 ;set TRUE
    ret
ConsoleThread endp

RARCallbackProc	PROC msg:DWORD, userData:DWORD, p1:DWORD, p2:DWORD
;  RAR callback proc for data/volume processing

    .if msg == UCM_CHANGEVOLUME
        .if p2 == RAR_VOL_NOTIFY
            invoke lstrcpy,addr strBuffer,p1
            invoke SendDlgItemMessage,hExtract,3013,WM_SETTEXT,0,addr strBuffer
            return 1
        .elseif p2 == RAR_VOL_ASK
            invoke lstrcpy,addr strBuffer,addr RVolAskMsg
            invoke lstrcat,addr strBuffer,p1
            invoke MessageBox,hExtract,addr strBuffer,addr caption,MB_OKCANCEL or MB_ICONINFORMATION
            .if eax == IDOK
                return 1
            .else
                return -1
            .endif
        .endif

    .elseif msg == UCM_PROCESSDATA
        .if abort_thread == 1  ;has thread been aborted?
            return -1
        .endif
      ;check if processing file has changed
        mov eax, FileCRC
        .if HeaderData.FileCRC != eax ;new file
            mov eax, p2 ;n of extracted bytes
            mov nBytesExtracted, eax
            mov eax, HeaderData.FileCRC
            mov FileCRC, eax
        .else ;still on the same file
            mov eax, p2
            add nBytesExtracted,eax
        .endif

        .if HeaderData.UnpSize > eax
          ;get percent of current extraction
            fild nBytesExtracted     ;load nBytesExtracted on TOS
            mov dummy_dd, 100
            fimul dummy_dd
            fidiv HeaderData.UnpSize			;divides both
            fistp dummy_dd		;save integer from TOS to nMBytesFree
          ;--same without floating point--
            ;mov eax, nBytesExtracted
            ;mov ebx, 100
            ;mul ebx ;result in edx:eax
            ;div HeaderData.UnpSize ;soure=edx:eax, result in eax
            ;mov dummy_dd,eax
          ;----------------------------
        .else
            mov eax,100
            mov dummy_dd,eax
        .endif
        invoke SendDlgItemMessage,hExtract,3004,PBM_SETPOS,dummy_dd,0
        invoke wsprintf,addr strBuffer,addr nFormatStr2,dummy_dd
        invoke SendDlgItemMessage,hExtract,3005,WM_SETTEXT,0,addr strBuffer

      ;get overall progress percentage
        finit       ;init fpu
        fld nOverallBytesExtracted     ;load on tos
        fiadd p2        ;add n of extracted bytes
        fst nOverallBytesExtracted    ;save value
        fld nOverallBytesExtracted     ;load again
        mov dummy_dd,100
        fimul dummy_dd        ;mul tos by 100
        fld nBytesReq      ;load max extracted size
        fdivp ST(1),ST(0)       ;divide to get percentage
        fistp dummy_dd        ;save value
        invoke SendDlgItemMessage,hExtract,3001,PBM_SETPOS,dummy_dd,0
        invoke wsprintf,addr strBuffer,addr nFormatStr2,dummy_dd
        invoke SendDlgItemMessage,hExtract,3011,WM_SETTEXT,0,addr strBuffer
    	return 1

    .elseif msg == UCM_NEEDPASSWORD
        invoke lstrcpy,p1,addr pass
        return 0

    .endif
    xor eax,eax
    ret

RARCallbackProc ENDP

LoadResFile PROC resName:DWORD,resId,outDir
            LOCAL resHandle,tmp,hFile,lpRes
            LOCAL path[255]:BYTE
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
;loads a specified resource and returns address in eax and size in ebx
;writes file to outDir if len>0
;  created: 2002.08.26 (fm)
; modified: 2003.08.27 (fm)
    invoke lstrlen,outDir
    .if eax == 0  ;load the resource and return address in eax and size in ebx
        ;get memory address of resource
        invoke FindResource,0,resId,10   ;10=RT_RCDATA
        mov resHandle,eax
        invoke LoadResource,0,resHandle
        push eax
        invoke SizeofResource,0,resHandle
        mov ebx,eax
        pop eax
        ret
    .else
        ;adding backslash and filename
        invoke lstrcpy,addr path,outDir
            mov tmp,05Ch ;"\"
            invoke lstrcat,addr path,addr tmp
            ;;temp dir ends with "\"
        invoke lstrcat,addr path,resName
    
        ;create File
        invoke CreateFile,addr path,GENERIC_WRITE,0,0,CREATE_ALWAYS,FILE_ATTRIBUTE_ARCHIVE,0
        mov hFile,eax

        ;get memory address of resource
        invoke FindResource,0,resId,10   ;10=RT_RCDATA
        mov resHandle,eax
        invoke LoadResource,0,resHandle
        mov lpRes,eax

        invoke SizeofResource,0,resHandle
        mov ebx,eax
        push ebx
        invoke WriteFile,hFile,lpRes,ebx,addr tmp,0
        invoke CloseHandle,hFile
        pop ebx
        mov eax,lpRes
        ret
    .endif
LoadResFile ENDP

PaintProc proc hWin:DWORD,hBmp:DWORD,wx:DWORD,hx:DWORD

    LOCAL hDC   :DWORD,hOld:DWORD,memDC:DWORD,ps:PAINTSTRUCT

    invoke BeginPaint,hWin,addr ps
    mov hDC,eax

    invoke CreateCompatibleDC,hDC
    mov memDC,eax
   
    invoke SelectObject,memDC,hBmp
    mov hOld,eax
    
    invoke BitBlt,hDC,0,0,wx,hx,memDC,0,0,SRCCOPY ;image size 245x260
    invoke SelectObject,hDC,hOld

    invoke DeleteDC,memDC
    invoke EndPaint,hWin,addr ps
    ret

PaintProc endp

BrowseProc proc hWin:DWORD,uMsg:DWORD,wParam:DWORD,lParam:DWORD
; =*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
;  Proc to choose the desired program directory


    .if uMsg == WM_INITDIALOG
        mov eax,hWin
        mov hWndBrowse,eax
        invoke GetDlgItem,hWin,5502
        mov hList,eax

        invoke SetWindowText,hWin,addr DlgItemTxt5500
        invoke SetDlgItemText,hWin,2,addr DlgItemTxt2
        invoke SetDlgItemText,hWin,5505,addr DlgItemTxt5505
        invoke SetDlgItemText,hWin,5504,addr DlgItemTxt5504        

        invoke SetCurrentDirectory,addr targetDir
        .if eax == 0
            invoke lstrcpyn,addr strBuffer,addr targetDir,4
            invoke SetCurrentDirectory,addr strBuffer
        .endif
        invoke GetCurrentDirectory,MAX_PATH,addr strBuffer
        invoke SetDlgItemText,hWin,5501,addr strBuffer

        invoke SetDlgItemText,hWin,5503,addr targetDirName
        invoke SendDlgItemMessage,hWin,5502,LB_DIR,DDL_EXCLUSIVE or DDL_DIRECTORY or DDL_DRIVES,addr patn
        invoke lstrlen,addr strBuffer
        .if eax > 3     ;add root dir if not in root already
            invoke SendMessage,hList,LB_INSERTSTRING,0,addr root
        .endif

        invoke SetWindowLong,hList,GWL_WNDPROC,ListBoxProc
        mov lpLstBox,eax


    .elseif uMsg == WM_COMMAND

        .if wParam == IDCANCEL
            invoke EndDialog,hWin,0
        
        .elseif wParam == IDOK
            ;;todo: der pfad muss auch nach ungueltigen Zeichen ueberprueft werden

            invoke GetDlgItemText,hWin,5501,addr strBuffer,MAX_PATH
            
           ;check target drive
            invoke lstrcpyn,addr dummy_dd,addr strBuffer,4      ;copy "X:\",0
            invoke GetDriveType,addr dummy_dd
            .if (eax < 3) || (eax > 4)
                invoke MessageBox,hWin,addr ErrDrive,addr caption,MB_ICONWARNING
                jmp dirOK
            .endif

           ;check target directory string
            invoke GetDlgItemText,hWin,5503,addr strBuffer,MAX_PATH

            mov dummy_dd,"&"
            invoke InString,1,addr strBuffer+3,addr dummy_dd
            .if eax != 0
                jmp dirErr
            .endif
            
            mov dummy_dd,"%"
            invoke InString,1,addr strBuffer+3,addr dummy_dd
            .if eax != 0
                jmp dirErr
            .endif
            
            mov dummy_dd,":"
            invoke InString,1,addr strBuffer+3,addr dummy_dd
            .if eax != 0
                jmp dirErr
            .endif

            mov dummy_dd,""""
            invoke InString,1,addr strBuffer+3,addr dummy_dd
            .if eax != 0
                jmp dirErr
            .endif

            mov dummy_dd,"|"            
            invoke InString,1,addr strBuffer+3,addr dummy_dd
            .if eax != 0
                jmp dirErr
            .endif

            mov dummy_dd,"<"
            invoke InString,1,addr strBuffer+3,addr dummy_dd
            .if eax != 0
                jmp dirErr
            .endif

            mov dummy_dd,">"
            invoke InString,1,addr strBuffer+3,addr dummy_dd
            .if eax != 0
                jmp dirErr
            .endif

            mov dummy_dd,"@"
            invoke InString,1,addr strBuffer+3,addr dummy_dd
            .if eax != 0
                jmp dirErr
            .endif

            mov dummy_dd,"!"
            invoke InString,1,addr strBuffer+3,addr dummy_dd
            .if eax != 0
                jmp dirErr
            .endif

            mov dummy_dd,"*"
            invoke InString,1,addr strBuffer+3,addr dummy_dd
            .if eax != 0
                jmp dirErr
            .endif

            mov dummy_dd,"\"
            invoke InString,1,addr strBuffer+3,addr dummy_dd
            .if eax != 0
                jmp dirErr
            .endif

            mov dummy_dd,"/"
            invoke InString,1,addr strBuffer+3,addr dummy_dd
            .if eax != 0
                jmp dirErr
            .endif
            
            invoke GetDlgItemText,hWin,5501,addr targetDir,MAX_PATH ;get directory
            invoke GetDlgItemText,hWin,5503,addr targetDirName,MAX_PATH ;get desired program folder
            invoke EndDialog,hWin,1
            jmp dirOK
        dirErr:
            invoke MessageBox,hWin,addr ErrDirectory,addr caption,MB_ICONWARNING or MB_OK
        dirOK:
        .endif

    .elseif uMsg == WM_CLOSE
        invoke EndDialog,hWin,0
	    
    .endif

    xor eax,eax
    ret

BrowseProc endp

ListBoxProc proc hCtl:DWORD,uMsg:DWORD,wParam:DWORD,lParam:DWORD
;  Proc for BrowseDialog's listbox handling

    LOCAL Buffer[MAX_PATH]:BYTE

    .if uMsg == WM_LBUTTONDBLCLK
      jmp DoIt
    .elseif uMsg == WM_CHAR
      .if wParam == 13
        jmp DoIt
      .endif
    .endif
    jmp EndDo

    DoIt:
        invoke SendMessage,hCtl,LB_GETCURSEL,0,0
        mov dummy_dd,eax
        invoke SendMessage,hCtl,LB_GETTEXT,dummy_dd,addr Buffer
        invoke lstrlen,addr Buffer
        dec eax
        invoke lstrcpyn,addr strBuffer,addr Buffer+1,eax ; strcat dirname without "[" and "]"
        invoke SetCurrentDirectory,addr strBuffer
        .if eax == 0 ;failed! - maybe a drive was selected
            invoke lstrcpyn,addr strBuffer,addr Buffer+2,2 ; strcat dirname without "-]"
            mov dummy_dd,03ah ;":"
            invoke lstrcat,addr strBuffer,addr dummy_dd ;add ":" to path
            invoke SetCurrentDirectory,addr strBuffer
        .endif

        invoke SendMessage,hCtl,LB_RESETCONTENT,0,0
        invoke SendMessage,hCtl,LB_DIR,DDL_EXCLUSIVE or DDL_DIRECTORY or DDL_DRIVES,addr patn
        invoke GetCurrentDirectory,MAX_PATH,addr Buffer
        invoke lstrlen,addr Buffer
        .if eax > 3
            invoke SendMessage,hCtl,LB_INSERTSTRING,0,addr root
        .endif

        invoke GetCurrentDirectory,MAX_PATH,addr strBuffer
        invoke SetDlgItemText,hWndBrowse,5501,addr strBuffer

    EndDo:

    invoke CallWindowProc,lpLstBox,hCtl,uMsg,wParam,lParam

    ret

ListBoxProc endp

SpaceCheck PROC hWin:DWORD
;  check available & free space and en/disable "next" button

    invoke wsprintf,addr strBuffer,addr nFormatStr,nMBytesReq
    invoke SendDlgItemMessage,hWin,5004,WM_SETTEXT,0,addr strBuffer
    invoke lstrcpyn,addr strBuffer,addr targetDir,4
    invoke GetDiskFreeSpaceEx,addr strBuffer,addr nBytesFree,0,0
    finit                   ;init FPU
    fild nBytesFree         ;load on TOS
    fidiv oneMeg            ;div TOS by 1.048.576
    fistp nMBytesFree       ;save integer from TOS to nMBytesFree
    invoke wsprintf,addr strBuffer,addr nFormatStr,nMBytesFree
    invoke SendDlgItemMessage,hWin,5005,WM_SETTEXT,0,addr strBuffer
    mov eax,nMBytesReq
    .if eax > nMBytesFree ;insufficent disk space
        invoke SendMessage,hPropSheet,PSM_SETWIZBUTTONS,0,PSWIZB_BACK ;diable "next" button
    .else
        invoke SendMessage,hPropSheet,PSM_SETWIZBUTTONS,0,PSWIZB_NEXT or PSWIZB_BACK    ;enable "next button"
    .endif
    xor eax,eax
    ret

SpaceCheck ENDP

udw2str proc dwNumber:DWORD, pszString:DWORD

    push ebx
    push esi
    push edi

    mov     eax, [dwNumber]
    mov     esi, [pszString]
    mov     edi, [pszString]
    mov ecx,429496730

  @@redo:
    mov ebx,eax
    mul ecx
    mov eax,edx
    lea edx,[edx*4+edx]
    add edx,edx
    sub ebx,edx
    add bl,'0'
    mov [esi],bl
    inc esi
    test    eax, eax
    jnz     @@redo
    jmp     @@chks

  @@invs: 
    dec     esi
    mov     al, [edi]
    xchg    [esi], al
    mov     [edi], al
    inc     edi
  @@chks:
    cmp     edi, esi
    jb      @@invs

    pop edi
    pop esi
    pop ebx


    ret

udw2str endp


ErrorCode PROC hWin:DWORD,val:DWORD
    
    LOCAL buf[128]:BYTE
    LOCAL convstr[4]:BYTE
     
    xor ebx,ebx
    mov bx,"i%"
    mov dword ptr convstr,ebx
     
    invoke wsprintf,addr buf,addr convstr,val
    invoke MessageBox,hWin,addr buf,addr caption,MB_OK
    
    return val

ErrorCode endp

end start

