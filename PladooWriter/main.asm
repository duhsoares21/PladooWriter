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

EXTERN RegisterClassExW:PROC
EXTERN CreateWindowExW:PROC
EXTERN DefWindowProcW:PROC
EXTERN SetWindowPos:PROC
EXTERN ShowWindow:PROC
EXTERN UpdateWindow:PROC
EXTERN GetMessageW:PROC
EXTERN GetModuleHandleW:PROC
EXTERN TranslateMessage:PROC
EXTERN DispatchMessageW:PROC
EXTERN PostQuitMessage:PROC
EXTERN ExitProcess:PROC
EXTERN GetLastError:PROC
EXTERN GetMenu:PROC
EXTERN SendMessageW:PROC
EXTERN MoveWindow:PROC
EXTERN ShowWindow:PROC
EXTERN GetClientRect:PROC
EXTERN GetSystemMetrics:PROC
EXTERN CreateSolidBrush:PROC
EXTERN GetWindowTextLengthW:PROC
EXTERN GetWindowTextW:PROC
EXTERN SetWindowTextW:PROC
EXTERN CreateFileW:PROC
EXTERN MultiByteToWideChar:PROC
EXTERN ReadFile:PROC
EXTERN WriteFile:PROC
EXTERN CloseHandle:PROC
EXTERN GetOpenFileNameW:PROC
EXTERN GetSaveFileNameW:PROC
EXTERN LoadIconW:PROC
EXTERN LoadImageW:PROC

EXTERN EditHWND: HWND
EXTERN ChildWndProc: PROC

; =========================================================
; WNDCLASSEXW Offsets (x64)
; =========================================================

WC_cbSize           equ 00h
WC_style            equ 04h
WC_lpfnWndProc      equ 08h
WC_cbClsExtra       equ 10h
WC_cbWndExtra       equ 14h
WC_hInstance        equ 18h
WC_hIcon            equ 20h
WC_hCursor          equ 28h
WC_hbrBackground    equ 30h
WC_lpszMenuName     equ 38h
WC_lpszClassName    equ 40h
WC_hIconSm          equ 48h

; =========================================================
; MSG size
; =========================================================

MSG_SIZE            equ 30h

; =========================================================
; CreateWindowExW stack arguments
; =========================================================

CW_X                equ 20h
CW_Y                equ 28h
CW_WIDTH            equ 30h
CW_HEIGHT           equ 38h
CW_PARENT           equ 40h
CW_MENU             equ 48h
CW_INSTANCE         equ 50h
CW_PARAM            equ 58h

.data

ClassName  dw 'M','a','i','n','W','r','i','t','e','r',0
WindowTitle       dw 'P','l','a','d','o','o',' ','W','r','i','t','e','r',0

WndClass   db SIZEOF WNDCLASSEXW dup(0)
MsgData    db MSG_SIZE dup(0)

hBgBrush QWORD 0
hMainIcon QWORD 0
hSmallIcon QWORD 0

PUBLIC mainWidth
mainWidth QWORD 800

PUBLIC mainHeight
mainHeight QWORD 600

PUBLIC hEditInstance
hEditInstance HINSTANCE 0

mainHWND HWND 0

EditRect RECT <>
ofn OPENFILENAMEW <>

szFileName dw 't','e','x','t','o','.','t','x','t',0
szStringOut QWORD 0
EmptyString dw 0
DefaultTxtExt dw 't','x','t',0

EditTextLength DWORD 0
BytesRead DWORD 0
BytesWritten DWORD 0

hFile QWORD 0
Utf16Bom dw 0FEFFh

TextBuffer dw 1048576 dup(0)
FileByteBuffer db 2097152 dup(0)

FileNameBuffer dw 260 dup(0)
FilterString label WORD          ; or label BYTE - both work for lpstrFilter

    ; Text Files
    dw 'T','e','x','t',' ','F','i','l','e','s',' ','(','*','.','t','x','t',')',0
    dw '*','.','t','x','t',0

    ; Markdown
    dw 'M','a','r','k','d','o','w','n',' ','(','*','.','m','d',')',0
    dw '*','.','m','d',0

    ; All Files
    dw 'A','l','l',' ','F','i','l','e','s',' ','(','*','.','*',')',0
    dw '*','.','*',0,0


.code

; =========================================================
; Window Procedure
; =========================================================

WndProc PROC    

    cmp edx, WM_COMMAND
    je CommandHandler

    cmp edx, WM_DESTROY
    je DestroyWindow

    cmp edx, WM_CREATE
    je CreateWindow

    cmp edx, WM_SIZE
    je WindowResized

    sub rsp, 28h
    call DefWindowProcW
    add rsp, 28h
    ret

WindowResized:
    movzx r10d, r9w ; LOWORD(lParam) - new width

    mov r11d, r9d ; HIWORD(lParam) - new height
    shr r11d, 16

    mov rcx, EditHWND

    mov rdx, 0      ; x
    mov r8, 0       ; y

    mov r9, r10     ; width
    sub rsp, 38h
        
        mov qword ptr [rsp+20h], r11   ; height
        mov qword ptr [rsp+28h], 1  ; repaint

        call MoveWindow

        mov rcx, EditHWND
        mov rdx, SW_SHOW

        sub rsp, 28h
            call ShowWindow
        add rsp, 28h

    add rsp, 38h

    xor rax, rax
    ret

CreateWindow:

    sub rsp, 28h
    call ChildWndProc
    add rsp, 28h

    xor rax, rax
    ret

DestroyWindow:

    sub rsp, 28h

    xor ecx, ecx
    call PostQuitMessage

    add rsp, 28h

    xor rax, rax
    ret

CommandHandler:
    movzx rax, r8w
    cmp eax, ID_FILE_NEW
    je FileNew

    cmp eax, ID_FILE_OPEN
    je FileOpen

    cmp eax, ID_FILE_SAVE
    je FileSave

    cmp eax, ID_FILE_EXIT
    je FileExit

    jmp ContinueCode

    FileNew:
        mov word ptr [FileNameBuffer], 0

        mov rcx, EditHWND
        mov rdx, OFFSET EmptyString

        sub rsp, 28h
            call SetWindowTextW
        add rsp, 28h

        ret

    FileOpen:
        mov ofn.lStructSize, SIZEOF OPENFILENAMEW

        mov rax, mainHWND
        mov ofn.hwndOwner, rax

        lea rax, FileNameBuffer
        mov ofn.lpstrFile, rax

        mov ofn.nMaxFile, 260

        lea rax, FilterString
        mov ofn.lpstrFilter, rax

        mov ofn.Flags, OFN_PATHMUSTEXIST or OFN_FILEMUSTEXIST

        lea rcx, ofn

        sub rsp, 28h
            call GetOpenFileNameW
        add rsp, 28h

        test rax, rax
        jz OpenUserCancelled

        sub rsp, 38h

            lea rcx, FileNameBuffer
            mov rdx, GENERIC_READ
            mov r8, FILE_SHARE_READ
            xor r9, r9

            mov qword ptr [rsp+20h], OPEN_EXISTING
            mov qword ptr [rsp+28h], FILE_ATTRIBUTE_NORMAL
            mov qword ptr [rsp+30h], 0

            call CreateFileW

        add rsp, 38h

        mov hFile, rax

        cmp rax, -1
        jne OpenHandleOK

        int 3

        OpenHandleOK:

        sub rsp, 28h

            mov rcx, hFile
            mov rdx, OFFSET FileByteBuffer
            mov r8d, 2097150
            lea r9, BytesRead

            mov qword ptr [rsp+20h], 0

            call ReadFile

        add rsp, 28h

        test rax, rax
        jnz ReadFileOK

        int 3

        ReadFileOK:

        mov eax, BytesRead
        lea rdx, FileByteBuffer
        mov byte ptr [rdx+rax], 0
        mov byte ptr [rdx+rax+1], 0

        mov rcx, hFile
        sub rsp, 28h
            call CloseHandle
        add rsp, 28h

        cmp word ptr [FileByteBuffer], 0FEFFh
        jne CheckUtf8Bom

        mov rcx, EditHWND
        mov rdx, OFFSET FileByteBuffer + 2
        jmp OpenSetText

        CheckUtf8Bom:
        mov r10d, BytesRead
        mov r11, OFFSET FileByteBuffer

        cmp r10d, 3
        jb ConvertUtf8

        cmp byte ptr [FileByteBuffer], 0EFh
        jne ConvertUtf8

        cmp byte ptr [FileByteBuffer+1], 0BBh
        jne ConvertUtf8

        cmp byte ptr [FileByteBuffer+2], 0BFh
        jne ConvertUtf8

        add r11, 3
        sub r10d, 3

        ConvertUtf8:
        sub rsp, 38h

            mov ecx, CP_UTF8
            xor edx, edx
            mov r8, r11
            mov r9d, r10d
            lea rax, TextBuffer
            mov qword ptr [rsp+20h], rax
            mov qword ptr [rsp+28h], 1048575

            call MultiByteToWideChar

        add rsp, 38h

        test eax, eax
        jnz ConvertUtf8OK

        int 3

        ConvertUtf8OK:
        lea rdx, TextBuffer
        mov word ptr [rdx+rax*2], 0

        mov rcx, EditHWND
        mov rdx, OFFSET TextBuffer

        OpenSetText:
        sub rsp, 28h
            call SetWindowTextW
        add rsp, 28h

        OpenUserCancelled:
        ret

    FileSave:
        
        mov rcx, EditHWND
        sub rsp, 28h
            call GetWindowTextLengthW
        add rsp, 28h

        mov rcx, EditHWND
        mov rdx, OFFSET TextBuffer
        mov EditTextLength, eax
        mov r8d, EditTextLength
        add r8d, 1

        sub rsp, 28h
            call GetWindowTextW
        add rsp, 28h

        test rax, rax
        jnz GetWindowTextOK

        sub rsp, 28h
            call GetLastError
        add rsp, 28h

        test rax, rax
        jz GetWindowTextOK     ; empty text, not an error

        int 3

        GetWindowTextOK:

        mov ofn.lStructSize, SIZEOF OPENFILENAMEW

        mov rax, mainHWND
        mov ofn.hwndOwner, rax

        lea rax, FileNameBuffer
        mov ofn.lpstrFile, rax

        mov ofn.nMaxFile, 260

        lea rax, FilterString
        mov ofn.lpstrFilter, rax

        mov ofn.Flags, OFN_OVERWRITEPROMPT

        lea rax, DefaultTxtExt
        mov ofn.lpstrDefExt, rax

        lea rcx, ofn

        sub rsp, 28h
        call GetSaveFileNameW
        add rsp, 28h

        test rax, rax
        jz UserCancelled

        sub rsp, 38h

        lea rcx, FileNameBuffer
        mov rdx, GENERIC_WRITE
        xor r8, r8
        xor r9, r9

        mov qword ptr [rsp+20h], CREATE_ALWAYS
        mov qword ptr [rsp+28h], FILE_ATTRIBUTE_NORMAL
        mov qword ptr [rsp+30h], 0

        call CreateFileW

        add rsp, 38h

        sub rsp, 28h

            mov hFile, rax

            cmp rax, -1
            jne HandleOK

            int 3

            HandleOK:

            mov rcx, hFile
            mov rdx, OFFSET Utf16Bom
            mov r8d, 2
            lea r9, BytesWritten

            mov qword ptr [rsp+20h], 0

            call WriteFile

            test rax, rax
            jz WriteFileDone

            mov rcx, hFile
            mov rdx, OFFSET TextBuffer
            mov r8d, EditTextLength
            shl r8d, 1
            lea r9, BytesWritten

            mov qword ptr [rsp+20h], 0

            call WriteFile

            WriteFileDone:
        
        add rsp, 28h

        test rax, rax
        jnz WriteFileOK

        sub rsp, 28h
            call GetLastError
        add rsp, 28h

        int 3; FAILED WRITE

        WriteFileOK:
        mov rcx, hFile
        sub rsp, 28h
            call CloseHandle
        add rsp, 28h
        ret

        UserCancelled:
            ret

    FileExit:
        xor rcx, rcx
        sub rsp, 28h
            call ExitProcess
        add rsp, 28h
        ret

    ContinueCode:
        ret

WndProc ENDP

; =========================================================
; Entry Point
; =========================================================

main PROC

    mov rcx, SM_CXSCREEN
    sub rsp, 28h
        call GetSystemMetrics
    add rsp, 28h

    mov mainWidth, rax
    xor rax, rax

    mov rcx, SM_CYSCREEN
    sub rsp, 28h
        call GetSystemMetrics
    add rsp, 28h

    mov mainHeight, rax

    mov ecx, 00404080h ; RGB(80,64,64) em formato COLORREF
    sub rsp, 28h
        call CreateSolidBrush
    add rsp, 28h

    mov hBgBrush, rax 

    sub rsp, 78h

    ; ----------------------------------------
    ; Fill WNDCLASSEXW
    ; ----------------------------------------

    mov dword ptr [WndClass+WC_cbSize], SIZEOF WNDCLASSEXW

    mov dword ptr [WndClass+WC_style], 0

    lea rax, WndProc
    mov qword ptr [WndClass+WC_lpfnWndProc], rax

    xor rcx, rcx
    call GetModuleHandleW

    mov hEditInstance, rax

    mov rcx, hEditInstance
    mov edx, IDI_MAINICON
    mov r8d, IMAGE_ICON
    mov r9d, 32
    mov qword ptr [rsp+20h], 32
    
    xor rax, rax
    mov qword ptr [rsp+28h], rax
    
    call LoadImageW
    mov hMainIcon, rax

    mov rcx, hEditInstance
    mov edx, IDI_MAINICON
    mov r8d, IMAGE_ICON
    mov r9d, 16

    mov qword ptr [rsp+20h], 16
    xor rax, rax
    mov qword ptr [rsp+28h], rax

    call LoadImageW
    mov hSmallIcon, rax

    mov rax, hEditInstance
    mov qword ptr [WndClass+WC_hInstance], rax

    mov rax, hMainIcon
    mov qword ptr [WndClass+WC_hIcon], rax

    mov rax, hSmallIcon
    mov qword ptr [WndClass+WC_hIconSm], rax

    mov qword ptr [WndClass+WC_hCursor], 0

    mov rax, hBgBrush
    mov qword ptr [WndClass+WC_hbrBackground], rax

    mov qword ptr [WndClass+WC_lpszMenuName], IDR_MAINMENU

    lea rax, ClassName
    mov qword ptr [WndClass+WC_lpszClassName], rax

    lea rcx, WndClass
    call RegisterClassExW

    ; ----------------------------------------
    ; Create Window
    ; ----------------------------------------

    test eax,eax
    jnz RegOK

    call GetLastError
    int 3            ; Registration failed

    RegOK:

    mov rcx, 0
    lea rdx, ClassName
    lea r8, WindowTitle 
    mov r9d, WS_OVERLAPPEDWINDOW

    mov qword ptr [rsp+CW_X],      0
    mov qword ptr [rsp+CW_Y],      0
    
    mov rax, mainWidth
    mov qword ptr [rsp+CW_WIDTH],  rax

    mov rax, mainHeight
    mov qword ptr [rsp+CW_HEIGHT], rax

    mov qword ptr [rsp+CW_PARENT], 0
    mov qword ptr [rsp+CW_MENU],   0
    
    mov rax, hEditInstance
    mov qword ptr [rsp+CW_INSTANCE], rax

    mov qword ptr [rsp+CW_PARAM],  0

    call CreateWindowExW

    test rax,rax
    jnz CreateOK

    int 3            ; Window creation failed

    CreateOK:

    mov mainHWND, rax
    mov rbx, rax

    mov rcx, rbx
    mov edx, WM_SETICON
    mov r8d, ICON_BIG
    mov r9, hMainIcon
    call SendMessageW

    mov rcx, rbx
    mov edx, WM_SETICON
    mov r8d, ICON_SMALL
    mov r9, hSmallIcon
    call SendMessageW

    ; ----------------------------------------
    ; Show Window
    ; ----------------------------------------

    mov rcx, rbx
    mov edx, SW_SHOW
    call ShowWindow

    mov rcx, rbx

    call UpdateWindow

MessageLoop:

    lea rcx, MsgData
    xor rdx, rdx
    xor r8, r8
    xor r9, r9

    call GetMessageW

    test eax, eax
    jz ExitProgram

    lea rcx, MsgData
    call TranslateMessage

    lea rcx, MsgData
    call DispatchMessageW

    jmp MessageLoop

ExitProgram:

    xor ecx, ecx
    call ExitProcess

add rsp, 68h

main ENDP

END
