-- put former exec-once commands inside the func and former exec commands outside
hl.on("hyprland.start", function ()

    -- Cava-визуализатор на столе. Отдельный инстанс Quickshell дорогой (~130 МБ),
    -- поэтому его запускает watcher: только когда играет музыка.
    -- Ручное управление: `rice cava on|off|auto|status`.
    hl.exec_cmd("$HOME/.local/bin/rice-cava-watch")

    -- Десктоп-виджеты (память ~160 МБ glyph и ~180 МБ music-player).
    -- Тумблер: `rice widget glyph|music on|off|status`.
    -- rice:widgets begin
    -- hl.exec_cmd("qs -c music-player")
    -- hl.exec_cmd("qs -c chaldea-glyph")
    -- rice:widgets end

end)
