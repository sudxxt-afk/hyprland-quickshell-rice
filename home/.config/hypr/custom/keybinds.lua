------------------------------------------------------------------------
--  МОИ ХОТКЕИ поверх end-4.
--  Живёт в custom/, поэтому переживает обновления end-4.
--  ВАЖНО: строка в hl.unbind(...) должна посимвольно совпадать
--         с биндом end-4 (регистр тоже).
------------------------------------------------------------------------
local mainMod = "SUPER"
local terminal    = "kitty -1"
local fileManager = "nautilus"
local browser     = "chromium-browser --ozone-platform-hint=auto"
local menu        = "wofi --show drun"

------------------------------------------------------------------------
-- 1. Освобождаем клавиши, где у end-4 другое действие
------------------------------------------------------------------------
hl.unbind("SUPER + Q")   -- было: закрыть окно        -> терминал
hl.unbind("SUPER + B")   -- было: левый сайдбар      -> браузер
hl.unbind("SUPER + V")   -- было: клипборд шелла     -> история буфера (cliphist)
hl.unbind("SUPER + A")   -- было: левый сайдбар      -> скриншот области
hl.unbind("SUPER + C")   -- было: редактор кода      -> закрыть окно
hl.unbind("SUPER + T")   -- было: терминал           -> плавающее окно
hl.unbind("SUPER + P")   -- было: закрепить окно     -> псевдо-тайлинг
hl.unbind("SUPER + E")   -- было: файлменеджер авто  -> nautilus
hl.unbind("SUPER + W")   -- было: браузер авто       -> chromium
hl.unbind("Print")       -- было: весь экран в буфер -> свой скриншот в файл

------------------------------------------------------------------------
-- 2. Приложения
------------------------------------------------------------------------
hl.bind(mainMod .. " + Q",     hl.dsp.exec_cmd(terminal),    { description = "Терминал" })
hl.bind(mainMod .. " + E",     hl.dsp.exec_cmd(fileManager), { description = "Файловый менеджер" })
hl.bind(mainMod .. " + B",     hl.dsp.exec_cmd(browser),     { description = "Браузер" })
hl.bind(mainMod .. " + W",     hl.dsp.exec_cmd(browser),     { description = "Браузер (доп. клавиша)" })
hl.bind(mainMod .. " + space", hl.dsp.exec_cmd(menu),        { description = "Лаунчер (wofi)" })
hl.bind(mainMod .. " + R",     hl.dsp.exec_cmd(menu),        { description = "Лаунчер (wofi)" })

------------------------------------------------------------------------
-- 3. Окна и сессия
------------------------------------------------------------------------
hl.bind(mainMod .. " + C",         hl.dsp.window.close(),                      { description = "Закрыть окно" })
hl.bind(mainMod .. " + T",         hl.dsp.window.float({ action = "toggle" }),  { description = "Плавающее/плитка" })
hl.bind(mainMod .. " + P",         hl.dsp.window.pseudo(),                     { description = "Псевдо-тайлинг" })
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exit(),                              { description = "Выход из Hyprland" })

------------------------------------------------------------------------
-- 4. Буфер обмена
------------------------------------------------------------------------
hl.bind(mainMod .. " + V",
    hl.dsp.exec_cmd("cliphist list | wofi --dmenu | cliphist decode | wl-copy"),
    { description = "История буфера" })

------------------------------------------------------------------------
-- 5. Скриншоты (как было)
------------------------------------------------------------------------
hl.bind(mainMod .. " + A",     hl.dsp.exec_cmd("hyprshot -m region -z --clipboard-only"), { description = "Скриншот области -> буфер" })
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("hyprshot -m window -z --clipboard-only"), { description = "Скриншот окна -> буфер" })
hl.bind("Print",               hl.dsp.exec_cmd("hyprshot -m output -z -o ~/Pictures/Screenshots"), { description = "Скриншот экрана -> файл" })

------------------------------------------------------------------------
--  RICE: scratchpad-окна и группы
------------------------------------------------------------------------
-- Нажатие: если приложение ещё не запущено — запускаем (правило в rules.lua
-- само уводит окно на special-воркспейс), затем показываем/прячем этот воркспейс.
local function scratchpad(name, cmd)
    return function()
        local ws = hl.get_workspace("special:" .. name)
        if ws == nil or ws.windows == 0 then
            hl.exec_cmd(cmd)
        end
        hl.dispatch(hl.dsp.workspace.toggle_special(name))
    end
end

hl.bind("SUPER + Z", scratchpad("term", "kitty --class scratchpad-term"), { description = "Scratchpad: terminal" })
hl.bind("SUPER + Y", scratchpad("tg",   "/opt/Telegram/Telegram"),       { description = "Scratchpad: Telegram" })
hl.bind("SUPER + U", scratchpad("top",  "kitty --class scratchpad-btop -e btop"), { description = "Scratchpad: btop" })

-- Группы: окна складываются во вкладки в одном тайле
hl.bind("SUPER + H",         hl.dsp.group.toggle(),       { description = "Group: toggle" })
hl.bind("SUPER + SHIFT + J", hl.dsp.group.next(),         { description = "Group: next tab" })
hl.bind("SUPER + SHIFT + K", hl.dsp.group.prev(),         { description = "Group: previous tab" })
