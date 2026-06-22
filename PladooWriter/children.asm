; =========================================================
; Win32 Window - x64 MASM
; =========================================================

;========================================
;WINDOWS API LIBS
;========================================

INCLUDELIB user32.lib
INCLUDELIB kernel32.lib

;========================================
;MY INCLUDES
;========================================

INCLUDE structs.inc

;=========================================================
; Externs
;=========================================================

EXTERN CreateWindowExW:PROC
EXTERN CreateMenu: PROC
EXTERN SetMenu:PROC
EXTERN AppendMenuW: PROC
EXTERN DefWindowProcW:PROC
EXTERN GetLastError:PROC

EXTERN hEditInstance: HINSTANCE
EXTERN mainWidth: QWORD
EXTERN mainHeight: QWORD

.data

szEditClass dw 'E','D','I','T',0
szMenuFile dw 'F','i','l','e',0

PUBLIC EditHWND
EditHWND HWND 0

PUBLIC ChildWndProc

.code

ChildWndProc PROC
    ;RCX = hWnd
    ;RDX = message
    ;R8  = wParam
    ;R9  = lParam

    mov r12, rcx ; Store Parent HWND

    LabelCreateEdit:

        sub rsp, 28h
            call CreateEditText
        add rsp, 28h
    
    ret
ChildWndProc ENDP

CreateEditText PROC    
    ;20h is the shadow space for the first 4 parameters
    ;40h is the space for the 8 parameters passed via Stack 
    ;8h is the space for the return address (alignment)
    sub rsp, 68h

    xor rcx, rcx ;dwExStyle
    mov rdx, OFFSET szEditClass
    xor r8, r8 ;lpWindowName
    mov r9d, WS_CHILD or ES_MULTILINE or WS_BORDER or WS_VSCROLL or WS_HSCROLL

    ; ----------------------------
    ; stack params (CreateWindowExW)
    ; ----------------------------
    mov qword ptr [rsp+20h], 0        ; X
    mov qword ptr [rsp+28h], 0        ; Y
    
    mov qword ptr [rsp+30h], 800      ; Width
    mov qword ptr [rsp+38h], 600      ; Height

    mov qword ptr [rsp+40h], r12      ; Parent HWND
    mov qword ptr [rsp+48h], 100      ; HMENU (ID do controle)

    mov rax, hEditInstance
    mov qword ptr [rsp+50h], rax       ; HINSTANCE

    mov qword ptr [rsp+58h], 0         ; lpParam

    call CreateWindowExW
    mov EditHWND, rax

    test eax,eax
    jnz CreateOK

    call GetLastError
    int 3            ; CREATION failed

    CreateOK:

    add rsp, 68h

    ret
CreateEditText ENDP

END
