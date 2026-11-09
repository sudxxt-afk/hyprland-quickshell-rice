-- put former exec-once commands inside the func and former exec commands outside
hl.on("hyprland.start", function ()

    -- Cava-визуализатор на столе (свой лёгкий инстанс, ~см. notes/11-tune-log.md)
    hl.exec_cmd("qs -c cava")

    -- Десктоп-виджеты music-player и chaldea-glyph отключены ради памяти
    -- (экономия ~330 МБ, см. notes/11-tune-log.md).
    -- Вернуть при желании — раскомментировать:
    -- hl.exec_cmd("qs -c music-player")
    -- hl.exec_cmd("qs -c chaldea-glyph")

end)
