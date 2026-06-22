; =========================================================
;STRUCTS
; =========================================================

WNDCLASSEXW STRUCT
    cbSize         DWORD ?
    style          DWORD ?
    lpfnWndProc    QWORD ?
    cbClsExtra     DWORD ?
    cbWndExtra     DWORD ?
    hInstance      QWORD ?
    hIcon          QWORD ?
    hCursor        QWORD ?
    hbrBackground  QWORD ?
    lpszMenuName   QWORD ?
    lpszClassName  QWORD ?
    hIconSm        QWORD ?
WNDCLASSEXW ENDS

OPENFILENAMEW STRUCT
    lStructSize        DWORD   ?
    pad0               DWORD   ?       ; alinhamento

    hwndOwner          QWORD   ?
    hInstance          QWORD   ?

    lpstrFilter        QWORD   ?
    lpstrCustomFilter  QWORD   ?

    nMaxCustFilter     DWORD   ?
    nFilterIndex       DWORD   ?

    lpstrFile          QWORD   ?

    nMaxFile           DWORD   ?
    pad1               DWORD   ?

    lpstrFileTitle     QWORD   ?

    nMaxFileTitle      DWORD   ?
    pad2               DWORD   ?

    lpstrInitialDir    QWORD   ?
    lpstrTitle         QWORD   ?

    Flags              DWORD   ?

    nFileOffset        WORD    ?
    nFileExtension     WORD    ?

    lpstrDefExt        QWORD   ?

    lCustData          QWORD   ?
    lpfnHook           QWORD   ?
    lpTemplateName     QWORD   ?
    pvReserved         QWORD   ?

    dwReserved         DWORD   ?
    FlagsEx            DWORD   ?
OPENFILENAMEW ENDS

; =========================================================
;TYPEDEFS
; =========================================================

HWND        TYPEDEF QWORD
HINSTANCE   TYPEDEF QWORD
HICON       TYPEDEF QWORD
HCURSOR     TYPEDEF QWORD
HBRUSH      TYPEDEF QWORD
HMENU       TYPEDEF QWORD
LPARAM      TYPEDEF QWORD
WPARAM      TYPEDEF QWORD
LRESULT     TYPEDEF QWORD
LPVOID      TYPEDEF QWORD
LPCWSTR     TYPEDEF QWORD
UINT        TYPEDEF DWORD

; =========================================================
; Constants
; =========================================================

WS_OVERLAPPEDWINDOW equ 0CF0000h
SW_SHOW             equ 00005h
WM_CREATE           equ 0001h
WM_NCCREATE         equ 0081h
WM_SHOWWINDOW       equ 0018h
WM_DESTROY          equ 0002h
WM_COMMAND		    equ 0111h
WM_SIZE			    equ 0005h
WS_CHILD            equ 40000000h
WS_VISIBLE          equ 10000000h
WS_BORDER           equ 00800000h
WS_HSCROLL          equ 00100000h
WS_VSCROLL          equ 00200000h
NULL                equ 0000h

SW_SHOW             equ 0005h

SWP_NOMOVE          equ 0002h
SWP_NOZORDER        equ 0004h
EM_GETRECT          equ 00B2h
EM_SETRECT          equ 00B3h
EM_SETRECTNP        equ 00B4h

CREATE_ALWAYS           equ 00000002h
OPEN_EXISTING           equ 00000003h
FILE_ATTRIBUTE_NORMAL   equ 00000080h
FILE_SHARE_READ         equ 00000001h
GENERIC_READ            equ 80000000h
GENERIC_WRITE           equ 40000000h
CP_UTF8                 equ 65001
OFN_OVERWRITEPROMPT     equ 00000002h
OFN_PATHMUSTEXIST       equ 00000800h
OFN_FILEMUSTEXIST       equ 00001000h

IDI_MAINICON    equ 103

IDR_MAINMENU    equ 101
ID_FILE_NEW     equ 40001
ID_FILE_OPEN    equ 40002
ID_FILE_SAVE    equ 40003
ID_FILE_EXIT    equ 40004

; =========================================================
; Edit Control Styles (Win32 / Winuser.h)
; =========================================================

ES_LEFT         equ 0000h      ; Default: left-aligned text
ES_CENTER       equ 0001h      ; Center text
ES_RIGHT        equ 0002h      ; Right-align text

ES_MULTILINE    equ 0004h      ; Multi-line edit control
ES_UPPERCASE    equ 0008h      ; Convert input to uppercase
ES_LOWERCASE    equ 0010h      ; Convert input to lowercase

ES_PASSWORD     equ 0020h      ; Mask input (e.g. ****)
ES_AUTOVSCROLL  equ 0040h      ; Auto vertical scroll
ES_AUTOHSCROLL  equ 0080h      ; Auto horizontal scroll

ES_NOHIDESEL    equ 0100h      ; Keep selection visible when unfocused
ES_OEMCONVERT   equ 0400h      ; Convert text to OEM charset

ES_READONLY     equ 0800h      ; Read-only edit control
ES_WANTRETURN   equ 1000h      ; Enter inserts newline (multiline only)

ES_NUMBER       equ 2000h      ; Allow digits only (basic filter)

RECT STRUCT
    left    DWORD ?
    top     DWORD ?
    right   DWORD ?
    bottom  DWORD ?
RECT ENDS

SM_CXSCREEN equ 0
SM_CYSCREEN equ 1
SM_CXICON equ 11
SM_CYICON equ 12
SM_CXSMICON equ 49
SM_CYSMICON equ 50
IMAGE_ICON equ 1
ICON_SMALL equ 00000000h
ICON_BIG equ 00000001h
WM_SETICON equ 00000080h
LR_DEFAULTSIZE equ 00000040h
