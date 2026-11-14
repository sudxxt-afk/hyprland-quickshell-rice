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
local launcher    = os.getenv("HOME") .. "/.local/bin/rice-launcher"  -- rofi; Tab — другие режимы

------------------------------------------------------------------------
-- 1. Освобождаем клавиши, где у end-4 другое действие
------------------------------------------------------------------------
hl.unbind("SUPER + Q")   -- было: закрыть окно        -> терминал
hl.unbind("SUPER + B")   -- было: левый сайдбар      -> браузер
hl.unbind("SUPER + SUPER_L")  -- было: одиночный Super открывал поиск/обзор ii
hl.unbind("SUPER + SUPER_R")
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
hl.bind(mainMod .. " + space", hl.dsp.exec_cmd(launcher),    { description = "Лаунчер (rofi)" })
hl.bind(mainMod .. " + R",     hl.dsp.exec_cmd(launcher .. " run"), { description = "Запуск команды (rofi)" })

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
    hl.dsp.exec_cmd(launcher .. " clip"),
    { description = "История буфера" })

------------------------------------------------------------------------
-- 5. Скриншоты (как было)
------------------------------------------------------------------------
hl.bind(mainMod .. " + A",     hl.dsp.exec_cmd("hyprshot -m region -z --clipboard-only"), { description = "Скриншот области -> буфер" })
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("hyprshot -m window -z --clipboard-only"), { description = "Скриншот окна -> буфер" })
hl.bind("Print",               hl.dsp.exec_cmd("hyprshot -m output -z -o ~/Pictures/Screenshots"), { description = "Скриншот экрана -> файл" })

------------------------------------------------------------------------
--  RICE: выпадающий терминал
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


------------------------------------------------------------------------
--  RICE: Alt+Tab (идея из HyDE altab, но нативно)
------------------------------------------------------------------------
-- Alt+Tab — к предыдущему окну, где бы оно ни было; повторное нажатие возвращает.
hl.bind("ALT + Tab", function()
    local w = hl.get_last_window()
    if w then
        hl.dispatch(hl.dsp.focus({ window = "address:" .. w.address }))
        hl.dispatch(hl.dsp.window.bring_to_top())
    end
end, { description = "Window: previous (Alt+Tab)" })

-- Выбор обоев с превью (селектор ii; Ctrl+Super+T тоже работает)
hl.bind("SUPER + ALT + T", hl.dsp.global("quickshell:wallpaperSelectorToggle"), { description = "Wallpaper: picker" })

------------------------------------------------------------------------
--  RICE: игровой режим, btop-скретчпад, список окон, cava
------------------------------------------------------------------------
-- SUPER+SHIFT+G — анимации/блюр/тени выключить-включить (rice-gamemode)
hl.bind("SUPER + SHIFT + G", hl.dsp.exec_cmd("rice-gamemode"), { description = "Gamemode: toggle" })

-- SUPER+ALT+S — системный монитор btop на своём special-воркспейсе
hl.bind("SUPER + ALT + S", scratchpad("btop", "kitty --class scratchpad-btop -e btop"), { description = "Scratchpad: btop" })

-- ALT+` — список окон в rofi (Alt+Tab по-прежнему «назад»)
hl.bind("ALT + grave", hl.dsp.exec_cmd(launcher .. " window"), { description = "Windows: switcher (rofi)" })

-- SUPER+ALT+C — тумблер cava-виджета (rice cava — то же из терминала)
hl.bind("SUPER + ALT + C", hl.dsp.exec_cmd("rice-cava"), { description = "Cava: toggle" })

-- SUPER+SHIFT+Space — spawn region (идея из lilith): рисуешь мышью область,
-- выбираешь приложение в rofi — окно открывается floating ровно в ней. Escape — отмена.
hl.bind("SUPER + SHIFT + space", hl.dsp.exec_cmd("rice-spawn"), { description = "Spawn: window in drawn region" })

------------------------------------------------------------------------
--  RICE: spawn region без хоткея (как в lilith)
--  Зажми ЛКМ на пустом месте стола, растяни область и отпусти —
--  в ней откроется kitty. Бинды non_consuming: клики по окнам, панели
--  и виджетам проходят как обычно, ничего не ломается.
------------------------------------------------------------------------
local spawn_start = nil
-- Зона ресайза у рамки (border_size 2 + extend_border_grab_area 15):
-- клик в ней ресайзит окно, а не рисует область.
local SPAWN_PAD = 17

local function spawn_occupied(x, y)
    for _, w in ipairs(hl.get_windows()) do
        local ws = w.workspace
        -- ws.visible: только активный воркспейс и показанные special
        -- (w.visible истинно и для окон на других столах)
        if w.visible and not w.hidden and ws and ws.visible then
            local at, size = w.at, w.size
            if x >= at.x - SPAWN_PAD and x < at.x + size.x + SPAWN_PAD
                and y >= at.y - SPAWN_PAD and y < at.y + size.y + SPAWN_PAD then
                return true
            end
        end
    end
    for _, l in ipairs(hl.get_layers()) do
        -- layer 0 = обои (фон); 1+ = бар, виджеты, углы экрана
        if l.mapped and l.layer > 0
            and x >= l.x and x < l.x + l.w and y >= l.y and y < l.y + l.h then
            return true
        end
    end
    return false
end

hl.bind("mouse:272", function()
    local pos = hl.get_cursor_pos()
    if spawn_occupied(pos.x, pos.y) then
        spawn_start = nil
    else
        spawn_start = pos
    end
end, { mouse = true, non_consuming = true, description = "Spawn region: press on empty desktop" })

hl.bind("mouse:272", function()
    local start = spawn_start
    spawn_start = nil
    if not start then return end
    local pos = hl.get_cursor_pos()
    local w = math.abs(pos.x - start.x)
    local h = math.abs(pos.y - start.y)
    if w >= 40 and h >= 40 then
        local x, y = math.min(start.x, pos.x), math.min(start.y, pos.y)
        hl.exec_cmd(string.format("[float; size %d %d; move %d %d] kitty", w, h, x, y))
    end
end, { drag = true, non_consuming = true, description = "Spawn region: release -> kitty" })
