-- ═══════════════════════════════════════════════════════════════════════
--  Hyprland · Catppuccin Mocha rice
--  ~/.config/hypr/hyprland.lua   (Hyprland 0.56+, Lua-конфиг)
--
--  Перезагрузить после правок:  hyprctl reload
--  Проверить синтаксис:         hyprland --verify-config
-- ═══════════════════════════════════════════════════════════════════════

------------------------
---- ПРОГРАММЫ ---------
------------------------
local terminal    = "kitty"
local fileManager = "nautilus"
local browser     = "chromium-browser --ozone-platform-hint=auto"
local menu        = "wofi --show drun"

------------------------
---- МОНИТОР -----------
------------------------
hl.monitor({
    output   = "",
    mode     = "1920x1080@60",
    position = "auto",
    scale    = 1,
})

------------------------
---- ОКРУЖЕНИЕ ---------
------------------------
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("XCURSOR_THEME", "catppuccin-mocha-mauve-cursors")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "catppuccin-mocha-mauve-cursors")
hl.env("HYPRCURSOR_SIZE", "24")

------------------------
---- АВТОЗАПУСК --------
------------------------
hl.on("hyprland.start", function()
    hl.exec_cmd("hyprpaper")                       -- обои
    hl.exec_cmd("$HOME/.config/hypr/scripts/qs-session.sh") -- бар (Quickshell)
    hl.exec_cmd("mako")                            -- уведомления
    hl.exec_cmd("hypridle")                        -- простой / блокировка
    hl.exec_cmd("swayosd-server")                  -- OSD громкости и яркости
    hl.exec_cmd("wl-paste --watch cliphist store") -- история буфера обмена
    hl.exec_cmd("nm-applet --indicator")           -- сеть в трее
    hl.exec_cmd("blueman-applet")                  -- bluetooth в трее
    -- polkit-агент (окна ввода пароля) поднимается через D-Bus сам
end)

------------------------
---- ВНЕШНИЙ ВИД -------
------------------------
hl.config({
    general = {
        gaps_in     = 5,
        gaps_out    = 12,
        border_size = 2,

        col = {
            -- фирменный градиент: mauve -> blue
            active_border   = { colors = { "rgba(cba6f7ee)", "rgba(89b4faee)" }, angle = 45 },
            inactive_border = "rgba(45475aaa)",
        },

        layout           = "dwindle",
        resize_on_border = true, -- тянуть за границы, чтобы ресайзить
        snap             = { enabled = true },
    },

    decoration = {
        rounding         = 12,
        rounding_power   = 2.2,
        active_opacity   = 1.0,
        inactive_opacity = 0.94,

        blur = {
            enabled           = true,
            size              = 4,
            passes            = 1,   -- было 3 — самый большой выигрыш для UHD 620
            noise             = 0,
            contrast          = 1.0,
            brightness        = 0.9,
            vibrancy          = 0,   -- было 0.25
            vibrancy_darkness = 0,
            popups            = true, -- размывать контекстные меню
        },

        shadow = {
            enabled      = true,
            range        = 10,
            render_power = 2,
            color        = 0xcc11111b,
        },

        glow = {
            enabled      = false, -- отдельный проход по каждому окну — дорого для iGPU
        },
    },

    animations = { enabled = true },
})

------------------------
---- АНИМАЦИИ ----------
------------------------
hl.curve("md3",  { type = "bezier", points = { {0.05, 0.7}, {0.1, 1.0} } })
hl.curve("wind", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })

hl.animation({ leaf = "global",           enabled = true,  speed = 12.0, bezier = "default" })
hl.animation({ leaf = "border",           enabled = true,  speed = 5.4,  bezier = "md3" })
hl.animation({ leaf = "windows",          enabled = true,  speed = 4.8,  bezier = "wind" })
hl.animation({ leaf = "windowsIn",        enabled = true,  speed = 6.0,  bezier = "wind", style = "popin 85%" })
hl.animation({ leaf = "windowsOut",       enabled = true,  speed = 6.0,  bezier = "wind", style = "popin 90%" })
hl.animation({ leaf = "fade",             enabled = true,  speed = 3.0,  bezier = "md3" })
hl.animation({ leaf = "layers",           enabled = true,  speed = 3.8,  bezier = "md3" })
hl.animation({ leaf = "layersIn",         enabled = false })
hl.animation({ leaf = "layersOut",        enabled = false })
hl.animation({ leaf = "workspaces",       enabled = true,  speed = 4.1,  bezier = "md3", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = false })

------------------------
---- ВВОД --------------
------------------------
hl.config({
    input = {
        -- Первая раскладка задаёт раскладку БИНДОВ, поэтому ставим us первой:
        -- так латинские шорткаты (SUPER+Q, SUPER+E и т.д.) срабатывают в любой раскладке.
        kb_layout  = "us,ru",
        kb_options = "grp:alt_shift_toggle", -- Alt+Shift переключает раскладку
        follow_mouse = 1,
        sensitivity  = 0,

        touchpad = {
            natural_scroll          = true,
            tap_to_click            = true,
            tap_and_drag            = true,
            drag_lock               = 1,    -- продолжать перетаскивание после отрыва пальца
            disable_while_typing    = true,
            middle_button_emulation = true, -- тап тремя пальцами = средняя кнопка
            scroll_factor           = 0.8,  -- на ноутбуке скролл плавнее
        },
    },
})

-- Основная клавиатура: по умолчанию русская раскладка для ввода.
-- Раскладку БИНДОВ это не меняет (она берётся из глобального kb_layout = us,ru),
-- поэтому шорткаты продолжают работать в обеих раскладках.
hl.device({
    name      = "at-translated-set-2-keyboard",
    kb_layout = "ru,us",
})

-- ── ЖЕСТЫ ТАЧПАДА ───────────────────────────────────────────────
-- Доступные действия: workspace, special, fullscreen, float, move,
-- resize, close, cursor_zoom, scroll_move.
-- На одну пару «пальцы + направление» — только один жест.
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })   -- свайп ↔ воркспейсы
hl.gesture({ fingers = 3, direction = "vertical",   action = "fullscreen" })  -- свайп ↕ fullscreen окна
hl.gesture({ fingers = 4, direction = "horizontal", action = "special",
             workspace_name = "magic" })                                      -- 4 пальца ↔ скретчпад
hl.gesture({ fingers = 4, direction = "vertical",   action = "move" })        -- 4 пальца ↕ двигать окно в раскладке

-- Параметры инерции/срабатывания свайпа воркспейсов под тачпад ноутбука
hl.config({
    gestures = {
        workspace_swipe_distance                 = 300,
        workspace_swipe_cancel_ratio             = 0.35,
        workspace_swipe_invert                   = false,
        workspace_swipe_create_new               = false,
        workspace_swipe_forever                  = false,
        workspace_swipe_direction_lock           = true, -- не переключать воркспейс по диагональному свайпу
        workspace_swipe_direction_lock_threshold = 10,
        workspace_swipe_use_r                    = false,
    },
})

------------------------
---- ПРОЧЕЕ ------------
------------------------
hl.config({
    dwindle = {
        preserve_split = true,
        smart_split    = true,
    },

    cursor = {
        sync_gsettings_theme = false, -- курсор берём из XCURSOR_*, а не из GNOME
    },

    misc = {
        disable_hyprland_logo      = true,
        force_default_wallpaper    = 0, -- никаких аниме-обоев поверх hyprpaper
        background_color           = 0x11111b,
        allow_session_lock_restore = true,
        -- ноутбук: недолго держать в памяти «холодные» окна в фоне
        render_unfocused_fps       = 15,
    },

    -- ноутбук: полный экран отдаём напрямую в GPU — экономит батарею на видео
    render = {
        direct_scanout = 1,
    },

    ecosystem = {
        no_donation_nag = true,
        no_update_news  = true,
    },
})

------------------------
---- ПРАВИЛА СЛОЁВ -----
------------------------
hl.layer_rule({ match = { namespace = "waybar" },        blur = false })
hl.layer_rule({ match = { namespace = "wofi" },          blur = true, ignore_alpha = 0.3 })
hl.layer_rule({ match = { namespace = "rofi" },          blur = true, ignore_alpha = 0.3 })
hl.layer_rule({ match = { namespace = "notifications" }, blur = true, ignore_alpha = 0.3 })
hl.layer_rule({ match = { namespace = "swayosd" },       blur = true, ignore_alpha = 0.2 })

------------------------
---- ПРАВИЛА ОКОН ------
------------------------
hl.window_rule({ name = "suppress-maximize-events", match = { class = ".*" }, suppress_event = "maximize" })
hl.window_rule({ name = "pinentry-focus",           match = { class = "(pinentry-)(.*)" }, stay_focused = true })
hl.window_rule({ name = "float-pavucontrol",        match = { class = "^(org\\.pulseaudio\\.)?pavucontrol$" }, float = true, size = "820 620" })
hl.window_rule({ name = "float-blueman",            match = { class = "^(blueman-manager)$" }, float = true })
hl.window_rule({ name = "float-nm-editor",          match = { class = "^(nm-connection-editor)$" }, float = true })
hl.window_rule({ name = "float-hyprland-run",       match = { class = "hyprland-run" }, move = "20 monitor_h-120", float = true })
hl.window_rule({ name = "idle-inhibit-video",       match = { class = "^(vlc)$" }, idle_inhibit = "fullscreen" })
-- видео: без блюра и тени — заметная экономия GPU/батареи
hl.window_rule({ name = "no-blur-video",            match = { class = "^(mpv|vlc|org\\.videolan\\.vlc|celluloid)$" }, no_blur = true, no_shadow = true })

------------------------
---- КЕЙБИНДЫ ----------
------------------------
local mainMod = "SUPER"

-- приложения
hl.bind(mainMod .. " + Q",     hl.dsp.exec_cmd(terminal),    { description = "терминал" })
hl.bind(mainMod .. " + E",     hl.dsp.exec_cmd(fileManager), { description = "файловый менеджер" })
hl.bind(mainMod .. " + B",     hl.dsp.exec_cmd(browser),     { description = "браузер" })
hl.bind(mainMod .. " + space", hl.dsp.exec_cmd(menu),        { description = "лаунчер" })
hl.bind(mainMod .. " + R",     hl.dsp.exec_cmd(menu),        { description = "лаунчер (альтернатива)" })

-- одиночный Super открывает меню.
-- release = true: срабатывает на ОТПУСКАНИЕ Super, поэтому Super остаётся
-- рабочим модификатором. Если будет открываться и после SUPER+Q и т.п. —
-- заменить { release = true } на { long_press = true }.
hl.bind("SUPER_L", hl.dsp.exec_cmd(menu), { release = true, description = "меню (одиночный Super)" })

-- окна
hl.bind(mainMod .. " + C",         hl.dsp.window.close())
hl.bind(mainMod .. " + T",         hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F",         hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(mainMod .. " + P",         hl.dsp.window.pseudo())
hl.bind(mainMod .. " + I",         hl.dsp.layout("togglesplit"))

-- фокус: стрелки и hjkl
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + H",     hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L",     hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K",     hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J",     hl.dsp.focus({ direction = "down" }))

-- перемещение окон
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT + H",     hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + L",     hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + K",     hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + J",     hl.dsp.window.move({ direction = "down" }))

-- воркспейсы 1-5
for i = 1, 5 do
    hl.bind(mainMod .. " + " .. i,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mainMod .. " + Tab", hl.dsp.focus({ workspace = "previous" }))
hl.bind("ALT + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.bring_to_top())
end)

-- скретчпад (special workspace)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- мышь: SUPER + ЛКМ тянуть, SUPER + ПКМ ресайзить
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- скриншоты (hyprshot + satty)
hl.bind(mainMod .. " + A",         hl.dsp.exec_cmd("hyprshot -m region -z --clipboard-only"), { description = "область -> буфер" })
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd("hyprshot -m region -z -- satty --filename"), { description = "область -> satty" })
hl.bind(mainMod .. " + Print",     hl.dsp.exec_cmd("hyprshot -m window -z --clipboard-only"))
hl.bind("Print",                   hl.dsp.exec_cmd("hyprshot -m output -z -o ~/Pictures/Screenshots"))

-- буфер, бар, конфиг
hl.bind(mainMod .. " + V",         hl.dsp.exec_cmd("cliphist list | wofi --dmenu | cliphist decode | wl-copy"), { description = "история буфера" })
hl.bind(mainMod .. " + W",         hl.dsp.exec_cmd("systemctl --user restart quickshell.service"))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"))

-- система
hl.bind(mainMod .. " + M",         hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(mainMod .. " + ALT + L",   hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exit())

-- мультимедиа (работают и на экране блокировки)
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("swayosd-client --output-volume raise"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("swayosd-client --output-volume lower"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), { locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("swayosd-client --brightness raise"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness lower"), { locked = true, repeating = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
