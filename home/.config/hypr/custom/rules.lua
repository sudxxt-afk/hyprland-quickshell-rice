------------------------------------------------------------------------
--  ПРАВИЛА ОКОН И СЛОЁВ (мой слой поверх end-4).
--  end-4 задаёт свои правила в hyprland/rules.lua; здесь — то, чего у них
--  нет или что мне нужно иначе. Дубли не мешают: правила суммируются.
------------------------------------------------------------------------

------------------------------------------------------------------------
-- Слои (blur для лаунчера wofi — как в старом рисе)
------------------------------------------------------------------------
hl.layer_rule({ match = { namespace = "wofi" }, blur = true, ignore_alpha = 0.3 })

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
