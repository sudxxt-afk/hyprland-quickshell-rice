------------------------------------------------------------------------
--  ПРАВИЛА ОКОН И СЛОЁВ (мой слой поверх end-4).
--  end-4 задаёт свои правила в hyprland/rules.lua; здесь — то, чего у них
--  нет или что мне нужно иначе. Дубли не мешают: правила суммируются.
------------------------------------------------------------------------

------------------------------------------------------------------------
-- Слои: стекло под лаунчерами (rofi — основной, wofi оставлен на всякий случай)
------------------------------------------------------------------------
hl.layer_rule({ match = { namespace = "wofi" }, blur = true, ignore_alpha = 0.3 })
hl.layer_rule({ match = { namespace = "rofi" }, blur = true, ignore_alpha = 0.3, animation = "popin 92%" })

------------------------------------------------------------------------
-- Плавающие окна
------------------------------------------------------------------------
hl.window_rule({
    name  = "float-pavucontrol",
    match = { class = "^(org\\.pulseaudio\\.)?pavucontrol$" },
    float = true,
    size  = "820 620",
})
hl.window_rule({
    name  = "float-blueman",
    match = { class = "^(blueman-manager)$" },
    float = true,
})
hl.window_rule({
    name  = "float-nm-editor",
    match = { class = "^(nm-connection-editor)$" },
    float = true,
})

------------------------------------------------------------------------
-- Спец-поведение
------------------------------------------------------------------------
-- Диалоги пароля всегда получают фокус
hl.window_rule({
    name         = "pinentry-focus",
    match        = { class = "(pinentry-)(.*)" },
    stay_focused = true,
})
-- Подавить события maximize (иначе часть приложений «прыгает»)
hl.window_rule({
    name           = "suppress-maximize-events",
    match          = { class = ".*" },
    suppress_event = "maximize",
})
-- Видео: без блюра и тени — заметная экономия GPU/батареи
hl.window_rule({
    name      = "no-blur-video",
    match     = { class = "^(mpv|vlc|org\\.videolan\\.vlc|celluloid)$" },
    no_blur   = true,
    no_shadow = true,
})
-- Не гасить экран во время видео
hl.window_rule({
    name         = "idle-inhibit-video",
    match        = { class = "^(vlc|mpv)$" },
    idle_inhibit = "fullscreen",
})

------------------------
-- RICE: стекло и умные отступы
------------------------
-- end-4 выключает блюр у всех окон (rules.lua: class ".*" → no_blur).
-- Возвращаем его только тем, кто реально полупрозрачен, — на UHD 620 блюр не бесплатный.
hl.window_rule({
    name    = "glass-terminal",
    match   = { class = "^(kitty|foot|com\\.mitchellh\\.ghostty)$" },
    no_blur = false,
})
-- Редакторы и файловый менеджер: чуть прозрачные, когда не в фокусе
hl.window_rule({
    name    = "glass-inactive",
    match   = { class = "^(Code|code|Antigravity|obsidian|org\\.gnome\\.Nautilus)$" },
    opacity = "1.0 0.92",
    no_blur = false,
})

-- Одно окно на рабочем столе (или fullscreen-раскладка) — без отступов, рамки и скругления:
-- на 1080p ноутбуке место дороже красоты. Как только окон два — всё возвращается.
hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
hl.window_rule({
    name        = "smart-gaps-single",
    match       = { float = false, workspace = "w[tv1]" },
    border_size = 0,
    rounding    = 0,
})
hl.window_rule({
    name        = "smart-gaps-fullscreen",
    match       = { float = false, workspace = "f[1]" },
    border_size = 0,
    rounding    = 0,
})

------------------------
-- RICE: выпадающий терминал (бинд в custom/keybinds.lua)
-- Живёт на своём special-воркспейсе, плавает по центру и прячется по тому же хоткею.
------------------------
local scratchpads = {
    { ws = "term", class = "^(scratchpad-term)$",         size = { "(monitor_w*0.70)", "(monitor_h*0.60)" } },
}
for _, s in ipairs(scratchpads) do
    hl.window_rule({
        name      = "scratchpad-" .. s.ws,
        match     = { class = s.class },
        workspace = "special:" .. s.ws .. " silent",
        float     = true,
        size      = s.size,
        center    = true,
    })
end
