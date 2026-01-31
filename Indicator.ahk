#Requires AutoHotkey v2.0
#NoTrayIcon

; --- ДИРЕКТИВЫ ДЛЯ КОМПИЛЯТОРА ---
if !DirExist("flags")
    DirCreate("flags")

FileInstall("flags\ru.png", "flags\ru.png", 1)
FileInstall("flags\us.png", "flags\us.png", 1)
FileInstall("flags\ua.png", "flags\ua.png", 1)
FileInstall("flags\main.png", "flags\main.png", 1)
; ---------------------------------

; --- НАСТРОЙКИ ---
X_POS := 150      
Y_POS := 872     
SIZE := 72       
GLOBAL IS_LOCKED := 0
GLOBAL STARTUP_LNK := A_Startup "\" . PathGetFileNameWithoutExtension(A_ScriptName) . ".lnk"
; -----------------

links := Map(
    "ru", "https://cdn-icons-png.flaticon.com/512/197/197408.png",
    "us", "https://cdn-icons-png.flaticon.com/512/197/197374.png",
    "ua", "https://cdn-icons-png.flaticon.com/512/197/197572.png",
    "main", "https://cdn-icons-png.flaticon.com/512/814/814513.png"
)

for name, url in links {
    if !FileExist("flags\" name ".png")
        Download(url, "flags\" name ".png")
}

MyGui := Gui("+LastFound +AlwaysOnTop -Caption +ToolWindow +E0x80000")
MyGui.BackColor := "123456"
FlagPic := MyGui.Add("Picture", "x0 y0 w" SIZE " h" SIZE, "flags\ru.png")

; Создание меню
MyMenu := Menu()
MyMenu.Add("Русский (RU)", (*) => SetLanguage(0x0419))
MyMenu.Add("English (US)", (*) => SetLanguage(0x0409))
MyMenu.Add("Українська (UA)", (*) => SetLanguage(0x0422))
MyMenu.Add()
MyMenu.Add("Закрепить", ToggleLock)
MyMenu.Add("Автозапуск", ToggleStartup)
MyMenu.Add()
MyMenu.Add("Выход", (*) => ExitApp())

; Проверка автозапуска при старте
if FileExist(STARTUP_LNK)
    MyMenu.Check("Автозапуск")

WinSetTransColor("123456", MyGui)
MyGui.Show("x" . X_POS . " y" . Y_POS . " NoActivate")

MyGui.SetFont("s10 w700 cGreen", "Arial")
CloseBtn := MyGui.Add("Text", "x0 y0", "×")
CloseBtn.OnEvent("Click", (*) => ExitApp())

OnMessage(0x0201, MoveGui)
OnMessage(0x0204, ShowMenu)

MoveGui(*) {
    if !IS_LOCKED
        PostMessage(0xA1, 2,,, "A")
}

ShowMenu(*) {
    ; Снимаем все галочки с языков перед показом
    MyMenu.Uncheck("Русский (RU)")
    MyMenu.Uncheck("English (US)")
    MyMenu.Uncheck("Українська (UA)")
    
    ; Ставим галочку на текущий язык
    currLang := GetCurrentLangID()
    if (currLang = 0x0419)
        MyMenu.Check("Русский (RU)")
    else if (currLang = 0x0422)
        MyMenu.Check("Українська (UA)")
    else if (currLang = 0x0409)
        MyMenu.Check("English (US)")
        
    MyMenu.Show()
}

SetLanguage(langID) {
    Send("!{Tab}") 
    Sleep(150)
    if (targetHwnd := WinExist("A"))
        PostMessage(0x0050, 0, langID,, targetHwnd)
}

ToggleLock(*) {
    Global IS_LOCKED := !IS_LOCKED
    if IS_LOCKED
        MyMenu.Check("Закрепить")
    else
        MyMenu.Uncheck("Закрепить")
    ShowTip(IS_LOCKED ? "Закреплено" : "Разблокировано")
}

ToggleStartup(*) {
    if FileExist(STARTUP_LNK) {
        FileDelete(STARTUP_LNK)
        MyMenu.Uncheck("Автозапуск")
        ShowTip("Автозапуск выключен")
    } else {
        FileCreateShortcut(A_ScriptFullPath, STARTUP_LNK)
        MyMenu.Check("Автозапуск")
        ShowTip("Автозапуск включен")
    }
}

ShowTip(text) {
    ToolTip(text)
    SetTimer(() => ToolTip(), -1500)
}

SetTimer(UpdateLang, 150)

GetCurrentLangID() {
    Hwnd := WinExist("A")
    if !Hwnd 
        return 0
    ThreadID := DllCall("GetWindowThreadProcessId", "Ptr", Hwnd, "Ptr", 0)
    Layout := DllCall("GetKeyboardLayout", "Ptr", ThreadID, "Ptr")
    return Layout & 0xFFFF
}

UpdateLang() {
    Static lastLang := 0
    MyGui.Opt("+AlwaysOnTop")
    LangID := GetCurrentLangID()

    if (LangID != lastLang && LangID != 0) {
        if (LangID = 0x0419)
            FlagPic.Value := "flags\ru.png"
        else if (LangID = 0x0422)
            FlagPic.Value := "flags\ua.png"
        else
            FlagPic.Value := "flags\us.png"
        lastLang := LangID
    }
}

PathGetFileNameWithoutExtension(path) {
    return RegExReplace(path, "i)^.*\\(.+)\.[^.]+$", "$1")
}