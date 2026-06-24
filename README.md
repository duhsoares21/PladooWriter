# Pladoo Writer Documentation

## Overview

<img width="1919" height="1032" alt="image" src="https://github.com/user-attachments/assets/a236c5ae-b8c9-41af-9b9a-910da267a5f7" />

This project is a small Win32 text editor written in x64 MASM. It creates a main window, attaches a standard Windows `EDIT` control as the text area, and exposes a menu with basic file actions:

- `File > New`
- `File > Open`
- `File > Save`
- `File > Exit`

The application uses the Unicode Win32 API (`W` functions), stores text internally as UTF-16, and saves files as UTF-16LE with a BOM so Notepad and other Windows editors can detect the encoding reliably.

## Downloading and Installing

Pladoo Writer can be download directly from Github releases page here: https://github.com/duhsoares21/PladooWriter/releases/tag/1.0

Instructions for Github:

1. Download the executable from Github releases page and Save it to a folder of your choice
2. Double click the executable

or 

You can use Packably, a package manager for Windows, to download it. 

Instructions for Packably: 

1. Download Packably on https://www.packably.com.br
2. Install it
3. Run packl install pladoo-writer on your Windows terminal
4. Use the command pladoo-writer to run the application

## Source Files

### `main.asm`

`main.asm` contains the application entry point, the main window class registration, the main message loop, and the main window procedure.

It is responsible for:

- Registering the main window class with `RegisterClassExW`.
- Creating the main window with `CreateWindowExW`.
- Showing and updating the main window.
- Running the Win32 message loop.
- Handling main window messages in `WndProc`.
- Dispatching menu commands.
- Implementing file operations: New, Open, Save, Exit.
- Managing the file picker structure `OPENFILENAMEW`.
- Reading and writing UTF-16LE text files.

### `children.asm`

`children.asm` creates the child `EDIT` control used as the main text editing area.

It is responsible for:

- Receiving the parent window handle.
- Creating an `EDIT` control with `CreateWindowExW`.
- Storing the edit control handle in the public variable `EditHWND`.

The main window uses `EditHWND` later for resizing, reading text, setting text, and clearing text.

### `structs.inc`

`structs.inc` contains shared structures, type aliases, and constants.

It defines:

- `WNDCLASSEXW`
- `OPENFILENAMEW`
- Win32 handle typedefs such as `HWND`, `HINSTANCE`, `HMENU`
- Window styles such as `WS_OVERLAPPEDWINDOW`, `WS_CHILD`, `WS_BORDER`
- Message IDs such as `WM_CREATE`, `WM_COMMAND`, `WM_SIZE`, `WM_DESTROY`
- File constants such as `GENERIC_READ`, `GENERIC_WRITE`, `CREATE_ALWAYS`, `OPEN_EXISTING`
- Common dialog flags such as `OFN_OVERWRITEPROMPT`, `OFN_PATHMUSTEXIST`, `OFN_FILEMUSTEXIST`
- Menu IDs such as `ID_FILE_NEW`, `ID_FILE_OPEN`, `ID_FILE_SAVE`, `ID_FILE_EXIT`
- Edit control styles such as `ES_MULTILINE`

### `menu.rc` and `resource.h`

These files define the application menu and icon resources.

The menu contains:

- `New`
- `Open`
- `Save`
- `Exit`

Each menu item maps to an ID declared in `resource.h` and mirrored in `structs.inc`.

The application icon is stored as:

```text
IDI_MAINICON ICON "pladoo.ico"
```

Because `IDI_MAINICON` has a low resource ID, Windows can also use it as the executable icon in shell views.

## Unicode Model

The program uses the wide-character Win32 API:

- `RegisterClassExW`
- `CreateWindowExW`
- `DefWindowProcW`
- `GetMessageW`
- `DispatchMessageW`
- `GetWindowTextLengthW`
- `GetWindowTextW`
- `SetWindowTextW`
- `CreateFileW`
- `MultiByteToWideChar`
- `GetOpenFileNameW`
- `GetSaveFileNameW`

The `W` suffix means the API expects UTF-16 strings.

Important distinction:

- `CreateFileW` means the file path is passed as UTF-16.
- It does not automatically make the file contents Unicode.
- `WriteFile` writes raw bytes exactly as provided.

Because `TextBuffer` is a `dw` buffer, the text is UTF-16LE in memory. To make the saved file recognizable as UTF-16LE, the program writes a BOM first:

```asm
Utf16Bom dw 0FEFFh
```

On disk this becomes:

```text
FF FE
```

That tells Notepad and other editors that the file is UTF-16 little-endian.

## x64 Windows Calling Convention

The project follows the Windows x64 calling convention.

The first four function arguments are passed in registers:

```text
RCX = argument 1
RDX = argument 2
R8  = argument 3
R9  = argument 4
```

Additional arguments are passed on the stack.

Every call must reserve 32 bytes of shadow space:

```text
20h bytes = space for RCX, RDX, R8, R9
```

The stack must also be 16-byte aligned before a `call`.

Common patterns in this project:

```asm
sub rsp, 28h
call SomeFunctionWithUpTo4Args
add rsp, 28h
```

For functions with 5 arguments:

```asm
sub rsp, 28h
mov qword ptr [rsp+20h], fifth_argument
call SomeFunction
add rsp, 28h
```

For `CreateWindowExW`, which has 12 arguments:

```asm
sub rsp, 68h
; first 4 args in RCX/RDX/R8/R9
; args 5-12 at [rsp+20h] through [rsp+58h]
call CreateWindowExW
add rsp, 68h
```

## Program Startup

The entry point is `main PROC` in `main.asm`.

Startup sequence:

1. Get screen width with `GetSystemMetrics(SM_CXSCREEN)`.
2. Get screen height with `GetSystemMetrics(SM_CYSCREEN)`.
3. Create a background brush with `CreateSolidBrush`.
4. Fill the `WNDCLASSEXW` structure.
5. Register the window class with `RegisterClassExW`.
6. Create the main window with `CreateWindowExW`.
7. Store the main window handle in `mainHWND`.
8. Show the window with `ShowWindow`.
9. Force initial painting with `UpdateWindow`.
10. Enter the message loop.

## Main Message Loop

The message loop uses:

```asm
GetMessageW
TranslateMessage
DispatchMessageW
```

`GetMessageW` retrieves messages from the thread message queue.

`TranslateMessage` translates keyboard input into character messages.

`DispatchMessageW` sends each message to `WndProc`.

The loop exits when `GetMessageW` returns zero, which normally happens after `PostQuitMessage`.

## Main Window Procedure

`WndProc` handles these messages:

- `WM_COMMAND`
- `WM_DESTROY`
- `WM_CREATE`
- `WM_SIZE`

All other messages are passed to `DefWindowProcW`.

### `WM_CREATE`

When the main window is created, `WndProc` calls `ChildWndProc` from `children.asm`.

`ChildWndProc` creates the edit control.

### `WM_SIZE`

When the main window is resized, the code extracts the new width and height from `lParam`.

Then it calls `MoveWindow` on `EditHWND` so the edit control fills the client area.

### `WM_COMMAND`

`WM_COMMAND` is used for menu actions.

The command ID comes from the low word of `wParam`.

The code compares it against:

- `ID_FILE_NEW`
- `ID_FILE_OPEN`
- `ID_FILE_SAVE`
- `ID_FILE_EXIT`

### `WM_DESTROY`

When the main window is destroyed, the code calls:

```asm
PostQuitMessage(0)
```

This causes the message loop to finish.

## Child Edit Control

The child edit control is created in `children.asm`.

The class name is:

```asm
szEditClass dw 'E','D','I','T',0
```

The control is created with:

```asm
CreateWindowExW
```

The important style bits are:

```asm
WS_CHILD or ES_MULTILINE or WS_BORDER
```

The resulting `HWND` is stored in:

```asm
EditHWND
```

`EditHWND` is declared public so `main.asm` can access it.

## File > New

`FileNew` performs two operations:

1. Clears the current path buffer:

```asm
mov word ptr [FileNameBuffer], 0
```

2. Clears the edit control:

```asm
SetWindowTextW(EditHWND, EmptyString)
```

This resets the current document state to an empty, unnamed document.

## File > Save

`FileSave` writes the current edit text to a user-selected file.

Save sequence:

1. Get the text length with `GetWindowTextLengthW`.
2. Copy text from the edit control into `TextBuffer` with `GetWindowTextW`.
3. Fill `OPENFILENAMEW`.
4. Show the save dialog with `GetSaveFileNameW`.
5. If the user cancels, return.
6. Open or create the selected file with `CreateFileW`.
7. Write the UTF-16LE BOM with `WriteFile`.
8. Write the text buffer with `WriteFile`.
9. Close the file handle with `CloseHandle`.

### Save Dialog

The save dialog uses:

```asm
GetSaveFileNameW
```

The selected path is stored in:

```asm
FileNameBuffer
```

The filter string is:

```text
Text Files (*.txt)
All Files (*.*)
```

### Save Encoding

The text is stored as UTF-16 in memory.

Before writing the text, the program writes:

```asm
Utf16Bom dw 0FEFFh
```

Then it writes the text bytes.

`GetWindowTextLengthW` returns a count in UTF-16 characters, not bytes. `WriteFile` expects bytes, so the code multiplies by 2:

```asm
mov r8d, EditTextLength
shl r8d, 1
```

## File > Open

`FileOpen` reads a user-selected text file and loads it into the edit control.

The open path supports:

- UTF-16LE with BOM.
- UTF-8 with BOM.
- UTF-8 without BOM.

Open sequence:

1. Fill `OPENFILENAMEW`.
2. Show the open dialog with `GetOpenFileNameW`.
3. If the user cancels, return.
4. Open the file with `CreateFileW`.
5. Read raw bytes into `FileByteBuffer` with `ReadFile`.
6. Null-terminate the byte buffer with two zero bytes.
7. Close the file handle.
8. If the file starts with UTF-16LE BOM `FF FE`, skip the BOM and pass the buffer directly to `SetWindowTextW`.
9. Otherwise, treat the file as UTF-8, skip UTF-8 BOM `EF BB BF` if present, and convert it with `MultiByteToWideChar(CP_UTF8)`.
10. Null-terminate the converted UTF-16 text.
11. Load the text into the edit control with `SetWindowTextW`.

### Open Dialog

The open dialog uses:

```asm
GetOpenFileNameW
```

The selected path is written into:

```asm
FileNameBuffer
```

This means after opening a file, the save dialog starts from that selected path.

### Reading Text

The file is read with:

```asm
ReadFile
```

The program reads raw bytes into:

```asm
FileByteBuffer
```

`BytesRead` receives the actual byte count.

The byte buffer is terminated with two zero bytes so it is safe to use directly as UTF-16LE when the file has a UTF-16LE BOM:

```asm
mov eax, BytesRead
lea rdx, FileByteBuffer
mov byte ptr [rdx+rax], 0
mov byte ptr [rdx+rax+1], 0
```

The program converts UTF-8 input into:

```asm
TextBuffer
```

For UTF-8 files, the conversion uses:

```asm
MultiByteToWideChar(CP_UTF8, ...)
```

The return value is the number of UTF-16 characters written. The code then appends a UTF-16 null terminator:

```asm
lea rdx, TextBuffer
mov word ptr [rdx+rax*2], 0
```

### BOM Handling

If the first two bytes are:

```asm
0FEFFh
```

the file has a UTF-16LE BOM.

The program skips it by passing `FileByteBuffer + 2` to `SetWindowTextW`.

If the first three bytes are:

```text
EF BB BF
```

the file has a UTF-8 BOM. The program skips those three bytes and converts the remaining bytes to UTF-16.

If no BOM is present, the program assumes UTF-8 and converts the whole file.

## File > Exit

`FileExit` calls:

```asm
ExitProcess(0)
```

This immediately terminates the process.

## Important Buffers

### `TextBuffer`

```asm
TextBuffer dw 1048576 dup(0)
```

This is the main UTF-16 text buffer.

It can hold up to 1,048,576 UTF-16 code units, including the null terminator.

### `FileByteBuffer`

```asm
FileByteBuffer db 2097152 dup(0)
```

This is the raw file input buffer used by `File > Open`.

It stores bytes exactly as `ReadFile` returns them. UTF-8 data is converted from this buffer into `TextBuffer`; UTF-16LE data with BOM can be passed directly to `SetWindowTextW` after skipping the BOM.

### `FileNameBuffer`

```asm
FileNameBuffer dw 260 dup(0)
```

This receives the file path selected by `GetOpenFileNameW` or `GetSaveFileNameW`.

It is a UTF-16 path buffer.

### `FilterString`

`FilterString` is a double-null-terminated UTF-16 string used by the open/save dialogs.

It contains display names and patterns:

```text
Text Files (*.txt)
*.txt
All Files (*.*)
*.*
```

The final extra null terminator is required by the common dialog API.

## Important Handles

### `mainHWND`

Stores the main window handle.

Used as the owner for file dialogs.

### `EditHWND`

Stores the edit control handle.

Used by:

- `MoveWindow`
- `GetWindowTextLengthW`
- `GetWindowTextW`
- `SetWindowTextW`

### `hFile`

Stores the file handle returned by `CreateFileW`.

Used by:

- `ReadFile`
- `WriteFile`
- `CloseHandle`

## Common Win32 APIs Used

### Window APIs

- `RegisterClassExW`
- `CreateWindowExW`
- `DefWindowProcW`
- `LoadImageW`
- `SendMessageW`
- `ShowWindow`
- `UpdateWindow`
- `MoveWindow`
- `PostQuitMessage`

## Window Icons

The project uses `pladoo.ico` as the main application icon.

The resource ID is:

```asm
IDI_MAINICON equ 103
```

During startup, the program loads two icon sizes with `LoadImageW`:

- A large icon for taskbar and Alt-Tab style UI.
- A small icon for the title bar.

Those handles are stored in:

```asm
hMainIcon
hSmallIcon
```

They are assigned to the window class fields:

```asm
WNDCLASSEXW.hIcon
WNDCLASSEXW.hIconSm
```

After the main window is created, the program also sends:

```asm
WM_SETICON, ICON_BIG
WM_SETICON, ICON_SMALL
```

This ensures the icon is applied to the live window as well as the registered window class.

### Message APIs

- `GetMessageW`
- `TranslateMessage`
- `DispatchMessageW`

### Edit Control APIs

- `GetWindowTextLengthW`
- `GetWindowTextW`
- `SetWindowTextW`

### File APIs

- `CreateFileW`
- `ReadFile`
- `WriteFile`
- `CloseHandle`

### Dialog APIs

- `GetOpenFileNameW`
- `GetSaveFileNameW`

## Current File Format

The project currently saves text as:

```text
UTF-16LE with BOM
```

That means saved files begin with:

```text
FF FE
```

Then the file contains UTF-16LE text bytes.

This works well with Notepad.

## Current Limitations

The open path supports UTF-16LE with BOM and UTF-8 with or without BOM.

It does not currently convert:

- ANSI code pages.
- UTF-16BE.

The save path always shows the save dialog. It does not yet implement a separate "Save" versus "Save As" distinction.

The project uses fixed-size buffers:

- 260 UTF-16 characters for file paths.
- 1,048,576 UTF-16 code units for text.

Long paths and very large files would need additional handling.

## Build Notes

The project file currently requests a platform toolset that may not be installed on every machine.

This build command worked in the current environment:

```powershell
MSBuild.exe .\Project1.vcxproj /p:Configuration=Debug /p:Platform=x64 /p:PlatformToolset=v143
```

If Visual Studio reports a missing platform toolset, either install that toolset or retarget the project to the installed one.

## Debugging Notes

The source currently uses `int 3` as manual breakpoints on some error paths.

Common Win32 errors encountered during development:

- `ERROR_INVALID_WINDOW_HANDLE` (`1400`): usually caused by passing a bad `HWND`.
- `ERROR_INVALID_MENU_HANDLE` (`1401`): caused earlier by an incorrect `WS_BORDER` constant that actually set `WS_POPUP`.
- `ERROR_ACCESS_DENIED` (`5`): caused earlier by an incorrect `GENERIC_WRITE` constant or stale object files after changing an include.

When checking file operation failures, inspect the result of `GetLastError` immediately after the failed API call.
