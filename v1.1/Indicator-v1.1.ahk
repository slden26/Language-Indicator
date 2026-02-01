#Requires AutoHotkey v2.0
#SingleInstance Force
#NoTrayIcon

; --- НАСТРОЙКИ И ПУТИ ---
IniFile := "settings.ini"
IconFolder := "flags"
Global IS_LOCKED := IniRead(IniFile, "Settings", "Locked", 0)
DefaultX := IniRead(IniFile, "Settings", "PosX", 550)
DefaultY := IniRead(IniFile, "Settings", "PosY", 1000)
STARTUP_LNK := A_Startup "\" . RegExReplace(A_ScriptName, "\.ahk|\.exe", "") . ".lnk"

if !DirExist(IconFolder)
    DirCreate(IconFolder)

; --- СОЗДАНИЕ GUI ---
; Добавил +E0x08000000 (WS_EX_NOACTIVATE), чтобы окно не перехватывало фокус при клике
MyGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x08000000", "LangIndicator")
MyGui.BackColor := "123456"
WinSetTransColor("123456", MyGui)

FlagPic := MyGui.Add("Picture", "x0 y0 w72 h72", "")

; --- МЕНЮ ---
MyMenu := Menu()
MyMenu.Add("Закрепить", ToggleLock)
if IS_LOCKED
    MyMenu.Check("Закрепить")
MyMenu.Add("Автозапуск", ToggleStartup)
if FileExist(STARTUP_LNK)
    MyMenu.Check("Автозапуск")
MyMenu.Add()
MyMenu.Add("Выход", (*) => ExitApp())

MyGui.OnEvent("ContextMenu", (*) => MyMenu.Show())
OnMessage(0x0201, WM_LBUTTONDOWN) ; ЛКМ для перемещения

; --- ЗАПУСК ---
UpdateLang()
MyGui.Show("x" DefaultX " y" DefaultY " NoActivate")

; Таймер обновления (как в версии 1)
SetTimer(UpdateLang, 150)

; --- ФУНКЦИИ ---

UpdateLang() {
    Static lastLang := 0
    
    ; ВОТ ОН - СЕКРЕТ ИЗ ВЕРСИИ 1:
    ; Постоянно подтверждаем статус "поверх всех"
    MyGui.Opt("+AlwaysOnTop")
    
    ; Получаем текущий язык
    Hwnd := WinExist("A")
    if !Hwnd 
        return
    ThreadID := DllCall("GetWindowThreadProcessId", "Ptr", Hwnd, "Ptr", 0)
    Layout := DllCall("GetKeyboardLayout", "Ptr", ThreadID, "Ptr")
    LangID := Layout & 0xFFFF

    if (LangID != lastLang && LangID != 0) {
        FlagFile := (LangID = 0x0419) ? "ru.png" : (LangID = 0x0422) ? "ua.png" : "us.png"
        if FileExist(IconFolder "\" FlagFile)
            FlagPic.Value := IconFolder "\" FlagFile
        lastLang := LangID
    }
}

WM_LBUTTONDOWN(wParam, lParam, msg, hwnd) {
    if (hwnd = MyGui.Hwnd && !IS_LOCKED) {
        PostMessage(0xA1, 2,,, "ahk_id " MyGui.Hwnd)
        SetTimer(SavePosition, -500) ; Сохраняем после перетаскивания
    }
}

SavePosition() {
    MyGui.GetPos(&OutX, &OutY)
    IniWrite(OutX, IniFile, "Settings", "PosX")
    IniWrite(OutY, IniFile, "Settings", "PosY")
}

ToggleLock(*) {
    Global IS_LOCKED := !IS_LOCKED
    if IS_LOCKED
        MyMenu.Check("Закрепить")
    else
        MyMenu.Uncheck("Закрепить")
    IniWrite(IS_LOCKED, IniFile, "Settings", "Locked")
}

ToggleStartup(*) {
    if FileExist(STARTUP_LNK) {
        FileDelete(STARTUP_LNK)
        MyMenu.Uncheck("Автозапуск")
    } else {
        FileCreateShortcut(A_ScriptFullPath, STARTUP_LNK)
        MyMenu.Check("Автозапуск")
    }
}